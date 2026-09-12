package com.college.bridge.doubt.dto;

import java.time.LocalDateTime;

public record DoubtAnswerResponse(
        Long answerId,
        Long answeredById,
        String answeredByName,
        String answer,
        boolean verified,
        boolean answeredByTeacher,
        LocalDateTime createdAt
) {
}