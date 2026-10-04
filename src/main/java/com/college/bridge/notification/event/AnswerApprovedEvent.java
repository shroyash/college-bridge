package com.college.bridge.notification.event;

public record AnswerApprovedEvent(
        Long doubtId,
        Long answerId,
        Long approverUserId,
        Long answerAuthorUserId,
        Long doubtAuthorUserId,
        Long institutionId,
        long approvedVersion
) {}
