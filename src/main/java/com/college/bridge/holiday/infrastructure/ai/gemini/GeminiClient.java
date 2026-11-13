package com.college.bridge.holiday.infrastructure.ai.gemini;

import com.college.bridge.holiday.application.port.NoticeWritingException;
import com.college.bridge.holiday.config.HolidayProperties;
import com.college.bridge.holiday.infrastructure.ai.gemini.GeminiApi.GenerateRequest;
import com.college.bridge.holiday.infrastructure.ai.gemini.GeminiApi.GenerateResponse;
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

/** HTTP only: sends the request and maps every failure to NoticeWritingException. */
@Component
@Slf4j
class GeminiClient {

    /** Sent as a header, never in the URL, so the key cannot leak into access logs. */
    private static final String API_KEY_HEADER = "x-goog-api-key";

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

        // Spring Boot's builder keeps the app-wide metrics and tracing customizers.
        this.client = builder.baseUrl(ai.baseUrl()).requestFactory(factory).build();
    }

    @PostConstruct
    void warnIfNotConfigured() {
        if (isBlank(apiKey)) {
            log.warn("holiday.ai.api-key is not set: every holiday will use the template notices");
        }
    }

    GenerateResponse generate(GenerateRequest request) {
        if (isBlank(apiKey)) {
            throw new NoticeWritingException("holiday.ai.api-key is not configured", false);
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
            // 408 / 429 / 5xx can succeed later; 400 / 401 / 403 / 404 never will.
            boolean retryable = status == 408 || status == 429 || status >= 500;
            throw new NoticeWritingException("Gemini returned HTTP " + status, e, retryable);
        } catch (ResourceAccessException e) {
            throw new NoticeWritingException("Gemini unreachable or timed out", e, true);
        }
        if (response == null) {
            throw new NoticeWritingException("Empty response from Gemini", true);
        }
        return response;
    }

    private static boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}
