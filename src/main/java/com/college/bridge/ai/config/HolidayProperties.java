package com.college.bridge.holiday.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

import java.time.LocalTime;
import java.util.List;

@ConfigurationProperties(prefix = "holiday")
public record HolidayProperties(
        @DefaultValue Api api,
        @DefaultValue Sync sync,
        @DefaultValue Notice notice,
        @DefaultValue Ai ai) {

    public record Api(String baseUrl, @DefaultValue("public") String type) {}

    public record Sync(List<Integer> years) {}

    public record Notice(
            @DefaultValue("college_notices") String audienceTopic,
            @DefaultValue("true") boolean autoSendHolidayVariant,
            @DefaultValue("07:00") LocalTime autoSelectAt,
            @DefaultValue("English") String language,
            @DefaultValue("3") int aiMaxAttempts,
            @DefaultValue("the college") String institutionName) {}

    public record Ai(
            @DefaultValue("https://generativelanguage.googleapis.com") String baseUrl,
            @DefaultValue("gemini-2.5-flash") String model,
            String apiKey,
            @DefaultValue("20") int timeoutSeconds) {}
}
