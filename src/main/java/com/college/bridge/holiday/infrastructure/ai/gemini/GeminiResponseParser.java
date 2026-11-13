package com.college.bridge.holiday.infrastructure.ai.gemini;

import com.college.bridge.holiday.application.port.NoticeWriter.WrittenNotice;
import com.college.bridge.holiday.application.port.NoticeWriter.WrittenNotices;
import com.college.bridge.holiday.application.port.NoticeWritingException;
import com.college.bridge.holiday.domain.DraftOrigin;
import com.college.bridge.holiday.infrastructure.ai.gemini.GeminiApi.Candidate;
import com.college.bridge.holiday.infrastructure.ai.gemini.GeminiApi.GenerateResponse;
import com.college.bridge.holiday.infrastructure.ai.gemini.GeminiApi.Part;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

import static com.college.bridge.holiday.infrastructure.ai.gemini.GeminiPromptFactory.CLOSED_KEY;
import static com.college.bridge.holiday.infrastructure.ai.gemini.GeminiPromptFactory.OPEN_KEY;

/** Validates Gemini's answer and turns it into the application's WrittenNotices. */
@Component
class GeminiResponseParser {

    private static final int MAX_MODEL_LENGTH = 64; // notice_drafts.model column size

    private final ObjectMapper mapper;

    GeminiResponseParser(ObjectMapper mapper) {
        this.mapper = mapper;
    }

    WrittenNotices parse(GenerateResponse response, String fallbackModel) {
        String json = extractText(response);
        JsonNode root;
        try {
            root = mapper.readTree(stripFences(json));
        } catch (JsonProcessingException e) {
            throw new NoticeWritingException("Gemini returned invalid JSON", e, true);
        }
        return new WrittenNotices(
                notice(root, CLOSED_KEY),
                notice(root, OPEN_KEY),
                DraftOrigin.AI,
                modelName(response.modelVersion(), fallbackModel));
    }

    private String extractText(GenerateResponse response) {
        if (response.promptFeedback() != null && response.promptFeedback().blockReason() != null) {
            throw new NoticeWritingException("Gemini blocked the prompt: " + response.promptFeedback().blockReason(), false);
        }
        if (response.candidates() == null || response.candidates().isEmpty()) {
            throw new NoticeWritingException("Gemini returned no candidates", true);
        }
        Candidate candidate = response.candidates().get(0);
        String finish = candidate.finishReason();
        if (finish != null && !"STOP".equals(finish)) {
            // MAX_TOKENS / OTHER may succeed on retry; SAFETY will not.
            throw new NoticeWritingException("Gemini stopped early, finishReason=" + finish, !"SAFETY".equals(finish));
        }
        if (candidate.content() == null || candidate.content().parts() == null) {
            throw new NoticeWritingException("Gemini returned no content", true);
        }

        StringBuilder text = new StringBuilder();
        for (Part part : candidate.content().parts()) {
            if (Boolean.TRUE.equals(part.thought()) || part.text() == null) continue; // skip "thinking" parts
            text.append(part.text());
        }
        if (text.toString().isBlank()) {
            throw new NoticeWritingException("Gemini returned no text", true);
        }
        return text.toString();
    }

    private WrittenNotice notice(JsonNode root, String key) {
        String title = root.path(key).path("title").asText("").trim();
        String body = root.path(key).path("body").asText("").trim();
        if (title.isEmpty() || body.isEmpty()) {
            throw new NoticeWritingException("Gemini output is missing " + key + ".title/body", true);
        }
        return new WrittenNotice(title, body);
    }

    private static String modelName(String reported, String fallback) {
        String name = (reported == null || reported.isBlank()) ? fallback : reported;
        return name.length() > MAX_MODEL_LENGTH ? name.substring(0, MAX_MODEL_LENGTH) : name;
    }

    /** Some models still wrap JSON in ``` fences. */
    private static String stripFences(String text) {
        String trimmed = text.trim();
        if (trimmed.startsWith("```")) {
            trimmed = trimmed.replaceFirst("^```(?:json)?\\s*", "").replaceFirst("\\s*```$", "");
        }
        return trimmed;
    }
}
