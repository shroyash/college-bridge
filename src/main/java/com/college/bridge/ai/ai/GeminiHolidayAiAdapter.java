package com.college.bridge.holiday.ai;

import com.college.bridge.holiday.ai.GeminiApi.Content;
import com.college.bridge.holiday.ai.GeminiApi.GenerateRequest;
import com.college.bridge.holiday.ai.GeminiApi.GenerateResponse;
import com.college.bridge.holiday.ai.GeminiApi.GenerationConfig;
import com.college.bridge.holiday.config.HolidayProperties;
import com.college.bridge.holiday.port.HolidayAiPort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.List;

/** Asks Gemini ONCE for both notices (holiday + open) and returns them validated. */
@Component
@RequiredArgsConstructor
@Slf4j
public class GeminiHolidayAiAdapter implements HolidayAiPort {

    private static final double TEMPERATURE = 0.4;       // low: consistent, formal wording
    private static final int MAX_OUTPUT_TOKENS = 2048;   // headroom in case the model "thinks" first

    private final GeminiClient client;
    private final GeminiNoticeParser parser;
    private final HolidayProperties props;

    @Override
    public GeneratedNotices generate(HolidayContext ctx) {
        GenerateRequest request = new GenerateRequest(
                Content.ofText(null, HolidayPromptFactory.SYSTEM_PROMPT),
                List.of(Content.ofText("user",
                        HolidayPromptFactory.userPrompt(ctx, props.notice().institutionName()))),
                new GenerationConfig(TEMPERATURE, MAX_OUTPUT_TOKENS,
                        "application/json", HolidayPromptFactory.RESPONSE_SCHEMA));

        long start = System.nanoTime();
        GenerateResponse response = client.generate(request);
        long latencyMs = (System.nanoTime() - start) / 1_000_000;

        GeneratedNotices result = parser.parse(response, props.ai().model());

        log.info("Gemini notices generated: holiday='{}' model={} latencyMs={} totalTokens={}",
                ctx.holidayName(), result.model(), latencyMs,
                response.usageMetadata() == null ? null : response.usageMetadata().totalTokenCount());
        log.debug("Gemini output: {}", result);
        return result;
    }
}
