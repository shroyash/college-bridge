package com.college.bridge.holiday.infrastructure.ai.gemini;

import com.college.bridge.holiday.application.port.NoticeWriter;
import com.college.bridge.holiday.config.HolidayProperties;
import com.college.bridge.holiday.infrastructure.ai.gemini.GeminiApi.Content;
import com.college.bridge.holiday.infrastructure.ai.gemini.GeminiApi.GenerateRequest;
import com.college.bridge.holiday.infrastructure.ai.gemini.GeminiApi.GenerateResponse;
import com.college.bridge.holiday.infrastructure.ai.gemini.GeminiApi.GenerationConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.List;

/** Adapter: implements the NoticeWriter port with ONE Gemini call that returns both notices. */
@Component
@Slf4j
@RequiredArgsConstructor
public class GeminiNoticeWriter implements NoticeWriter {

    private static final double TEMPERATURE = 0.4;      // low: consistent, formal wording
    private static final int MAX_OUTPUT_TOKENS = 2048;  // headroom in case the model "thinks" first

    private final GeminiClient client;
    private final GeminiResponseParser parser;
    private final HolidayProperties props;

    @Override
    public WrittenNotices write(NoticeRequest request) {
        GenerateRequest apiRequest = new GenerateRequest(
                Content.ofText(null, GeminiPromptFactory.SYSTEM_PROMPT),
                List.of(Content.ofText("user", GeminiPromptFactory.userPrompt(request))),
                new GenerationConfig(TEMPERATURE, MAX_OUTPUT_TOKENS,
                        "application/json", GeminiPromptFactory.RESPONSE_SCHEMA));

        long start = System.nanoTime();
        GenerateResponse response = client.generate(apiRequest);
        long latencyMs = (System.nanoTime() - start) / 1_000_000;

        WrittenNotices notices = parser.parse(response, props.ai().model());
        log.info("Gemini wrote notices: holiday='{}' model={} latencyMs={} totalTokens={}",
                request.holidayName(), notices.model(), latencyMs,
                response.usageMetadata() == null ? null : response.usageMetadata().totalTokenCount());
        log.debug("Gemini output: {}", notices);
        return notices;
    }
}
