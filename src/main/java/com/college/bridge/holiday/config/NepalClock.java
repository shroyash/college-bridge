package com.college.bridge.holiday.config;

import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;

/**
 * The single source of "now" for the holiday feature, always in Nepal time.
 * Services never call LocalDate.now() directly, so time is correct on any server and easy to fake in tests.
 */
@Component
public class NepalClock {

    /** Compile-time constant so it can be used inside @Scheduled(zone = ...). */
    public static final String ZONE = "Asia/Kathmandu";

    private static final ZoneId NEPAL = ZoneId.of(ZONE);

    private final Clock clock;

    /** Used by Spring. */
    public NepalClock() {
        this(Clock.system(NEPAL));
    }

    /** Used by tests to freeze or move time. */
    NepalClock(Clock clock) {
        this.clock = clock.withZone(NEPAL);
    }

    public LocalDate today() { return LocalDate.now(clock); }

    public LocalTime timeNow() { return LocalTime.now(clock); }

    public Instant instantNow() { return clock.instant(); }
}
