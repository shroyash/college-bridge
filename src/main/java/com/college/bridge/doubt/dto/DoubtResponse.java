package com.college.bridge.doubt.dto;

import com.college.bridge.doubt.enums.DoubtStatus;

import java.time.LocalDateTime;
import java.util.List;

public record DoubtResponse(
        Long doubtId,
        Long subjectId,
        String subjectName,
        Long studentId,
        String studentName,
        String question,
        DoubtStatus status,
        Boolean helpful,
        LocalDateTime createdAt,
        long answerCount,
        long verifiedAnswerCount,
        long unverifiedAnswerCount,
        List<DoubtAnswerResponse> answers
) {
}