package com.college.bridge.notification.event;

public record DoubtPostedEvent(
        Long doubtId,
        Long subjectId,
        String subjectName,
        Long authorUserId,
        Long actorUserId,
        Long institutionId,
        String preview
) {
    public DoubtPostedEvent(
            Long doubtId,
            Long subjectId,
            Long authorUserId,
            Long actorUserId,
            Long institutionId,
            String preview
    ) {
        this(doubtId, subjectId, null, authorUserId, actorUserId, institutionId, preview);
    }
}
