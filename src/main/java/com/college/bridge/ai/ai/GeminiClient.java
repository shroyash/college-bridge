package com.college.bridge.holiday.ai;

import com.college.bridge.holiday.ai.GeminiApi.GenerateRequest;
import com.college.bridge.holiday.ai.GeminiApi.GenerateResponse;
import com.college.bridge.holiday.config.HolidayProperties;
import com.college.bridge.holiday.port.HolidayAiException;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

import java.net.http.HttpClient;
import java.time.Duration;

/** HTTP only: sends the request and maps every failure to HolidayAiException. */
@Component
@Slf4j
class GeminiClient {

    private static final String API_KEY_HEADER = "x-goog-api-key"; // header, never the URL, so it can't leak into logs

    private final RestClient client;
    private final String model;
    private final String apiKey;

    GeminiClient(RestClient.Builder builder, HolidayProperties props) {
        HolidayProperties.Ai ai = props.ai();
        this.model = ai.model();
        this.apiKey = ai.apiKey();

        JdkClientHttpRequestFactory factory = new JdkClientHttpRequestFactory(
                HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build());
        factory.setReadTimeout(Duration.ofSeconds(Math.max(5, ai.timeoutSeconds())));

        // Boot's builder keeps your app-wide metrics/tracing customizers.
        this.client = builder.baseUrl(ai.baseUrl()).requestFactory(factory).build();
    }

    @PostConstruct
    void warnIfNotConfigured() {
        if (isBlank(apiKey)) {
            log.warn("holiday.ai.api-key is not set: every holiday draft will use the template fallback");
        }
    }

    GenerateResponse generate(GenerateRequest request) {
        if (isBlank(apiKey)) {
            throw new HolidayAiException("holiday.ai.api-key is not configured", false);
        }
        GenerateResponse response;
        try {
            response = client.post()
                    .uri("/v1beta/models/{model}:generateContent", model)
                    .header(API_KEY_HEADER, apiKey)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(request)
                    .retrieve()
                    .body(GenerateResponse.class);
        } catch (RestClientResponseException e) {
            int status = e.getStatusCode().value();
            // 429 / 5xx / 408 can succeed later. 400 / 401 / 403 / 404 never will.
            boolean retryable = status == 408 || status == 429 || status >= 500;
            throw new HolidayAiException("Gemini returned HTTP " + status, e, retryable);
        } catch (ResourceAccessException e) {
            throw new HolidayAiException("Gemini unreachable or timed out", e, true);
        }
        if (response == null) {
            throw new HolidayAiException("Empty response from Gemini", true);
        }
        return response;
    }

    private static boolean isBlank(String s) { return s == null || s.isBlank(); }
}
