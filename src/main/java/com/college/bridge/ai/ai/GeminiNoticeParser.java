package com.college.bridge.holiday.ai;

import com.college.bridge.holiday.ai.GeminiApi.Candidate;
import com.college.bridge.holiday.ai.GeminiApi.GenerateResponse;
import com.college.bridge.holiday.ai.GeminiApi.Part;
import com.college.bridge.holiday.port.HolidayAiException;
import com.college.bridge.holiday.port.HolidayAiPort.GeneratedNotices;
import com.college.bridge.holiday.port.HolidayAiPort.Notice;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

import static com.college.bridge.holiday.ai.HolidayPromptFactory.HOLIDAY_KEY;
import static com.college.bridge.holiday.ai.HolidayPromptFactory.OPEN_KEY;

/** Validates Gemini's answer and turns it into two Notice objects. */
@Component
class GeminiNoticeParser {

    private static final int MAX_MODEL_LENGTH = 64; // holiday_msg.model column size

    private final ObjectMapper mapper;

    GeminiNoticeParser(ObjectMapper mapper) {
        this.mapper = mapper;
    }

    GeneratedNotices parse(GenerateResponse response, String fallbackModel) {
        String json = extractText(response);
        JsonNode root;
        try {
            root = mapper.readTree(stripFences(json));
        } catch (JsonProcessingException e) {
            throw new HolidayAiException("Gemini returned invalid JSON", e, true);
        }
        return new GeneratedNotices(
                notice(root, HOLIDAY_KEY),
                notice(root, OPEN_KEY),
                modelName(response.modelVersion(), fallbackModel));
    }

    private String extractText(GenerateResponse response) {
        if (response.promptFeedback() != null && response.promptFeedback().blockReason() != null) {
            throw new HolidayAiException("Gemini blocked the prompt: " + response.promptFeedback().blockReason(), false);
        }
        if (response.candidates() == null || response.candidates().isEmpty()) {
            throw new HolidayAiException("Gemini returned no candidates", true);
        }
        Candidate candidate = response.candidates().get(0);
        String finish = candidate.finishReason();
        if (finish != null && !"STOP".equals(finish)) {
            // MAX_TOKENS / OTHER may succeed on retry; SAFETY will not.
            throw new HolidayAiException("Gemini stopped early, finishReason=" + finish, !"SAFETY".equals(finish));
        }
        if (candidate.content() == null || candidate.content().parts() == null) {
            throw new HolidayAiException("Gemini returned no content", true);
        }

        StringBuilder text = new StringBuilder();
        for (Part part : candidate.content().parts()) {
            if (Boolean.TRUE.equals(part.thought()) || part.text() == null) continue; // skip thinking parts
            text.append(part.text());
        }
        if (text.toString().isBlank()) {
            throw new HolidayAiException("Gemini returned no text", true);
        }
        return text.toString();
    }

    private Notice notice(JsonNode root, String key) {
        String title = root.path(key).path("title").asText("").trim();
        String body = root.path(key).path("body").asText("").trim();
        if (title.isEmpty() || body.isEmpty()) {
            throw new HolidayAiException("Gemini output is missing " + key + ".title/body", true);
        }
        return new Notice(title, body);
    }

    private static String modelName(String reported, String fallback) {
        String name = (reported == null || reported.isBlank()) ? fallback : reported;
        return name.length() > MAX_MODEL_LENGTH ? name.substring(0, MAX_MODEL_LENGTH) : name;
    }

    /** Some models still wrap JSON in ``` fences. */
    private static String stripFences(String s) {
        String t = s.trim();
        if (t.startsWith("```")) {
            t = t.replaceFirst("^```(?:json)?\\s*", "").replaceFirst("\\s*```$", "");
        }
        return t;
    }
}
