package com.college.bridge.notification.event;

public record DoubtAnsweredEvent(
        Long doubtId,
        Long answerId,
        Long answererUserId,
        Long doubtAuthorUserId,
        Long institutionId,
        String preview
) {}

