package com.college.bridge.holiday.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

import java.util.List;

/** Typed view of every {@code holiday.*} setting. Defaults live here so the feature works with minimal config. */
@ConfigurationProperties(prefix = "holiday")
public record HolidayProperties(
        @DefaultValue Api api,
        @DefaultValue Sync sync,
        @DefaultValue Notice notice,
        @DefaultValue Ai ai,
        @DefaultValue Publishing publishing) {

    /** The external holiday calendar. */
    public record Api(String baseUrl, @DefaultValue("public") String type) {}

    /** Which BS years the monthly job refreshes. */
    public record Sync(List<Integer> years) {}

    /** How shared drafts are written. */
    public record Notice(
            @DefaultValue("English") String language,
            @DefaultValue("3") int aiMaxAttempts) {}

    /** Gemini connection. */
    public record Ai(
            @DefaultValue("https://generativelanguage.googleapis.com") String baseUrl,
            @DefaultValue("gemini-2.5-flash") String model,
            String apiKey,
            @DefaultValue("20") int timeoutSeconds,
            @DefaultValue("2000") long retryBackoffMillis) {}

    /** Per-institution delivery retry rules. */
    public record Publishing(
            @DefaultValue("5") int maxAttempts,
            @DefaultValue("15") int staleAfterMinutes,
            @DefaultValue("100") int batchSize) {}
}
