package com.college.bridge.notification.event;

public record DoubtPostedEvent(
        Long doubtId,
        Long subjectId,
        Long authorUserId,
        Long actorUserId,
        Long institutionId,
        String preview
) {}
