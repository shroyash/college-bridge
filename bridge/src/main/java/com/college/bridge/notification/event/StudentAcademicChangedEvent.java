package com.college.bridge.notification.event;

public record StudentAcademicChangedEvent(
        Long studentId,
        Long userId,
        Long institutionId,
        Long actorUserId,
        String summary,
        String changeId
) {}
