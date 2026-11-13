package com.college.bridge.holiday.application.port;

/**
 * Naming of the per-institution FCM topics. Public on purpose: your login / token-refresh code must subscribe
 * each user to the SAME names (students to students(id), teachers to teachers(id)).
 */
public final class AudienceTopics {

    private AudienceTopics() {}

    public static String students(Long institutionId) {
        return "inst_" + institutionId + "_students";
    }

    public static String teachers(Long institutionId) {
        return "inst_" + institutionId + "_teachers";
    }
}
