package com.college.bridge.holiday.application.port;

/**
 * Naming of the per-institution FCM topics. Aligned with backend notification system convention
 * (tenant_{institutionId}_students and tenant_{institutionId}_teachers).
 */
public final class AudienceTopics {

    private AudienceTopics() {}

    public static String students(Long institutionId) {
        return "tenant_" + institutionId + "_students";
    }

    public static String teachers(Long institutionId) {
        return "tenant_" + institutionId + "_teachers";
    }
}
