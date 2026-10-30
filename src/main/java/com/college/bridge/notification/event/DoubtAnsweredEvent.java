package com.college.bridge.notification.event;

public record DoubtAnsweredEvent(
        Long doubtId,
        Long answerId,
        Long answererUserId,
        Long doubtAuthorUserId,
        Long institutionId,
        String preview,
        String subjectName
) {
    public DoubtAnsweredEvent(
            Long doubtId,
            Long answerId,
            Long answererUserId,
            Long doubtAuthorUserId,
            Long institutionId,
            String preview
    ) {
        this(doubtId, answerId, answererUserId, doubtAuthorUserId, institutionId, preview, null);
    }
}
