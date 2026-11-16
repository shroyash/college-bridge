package com.college.bridge.doubt.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateDoubtAnswerRequest(

        @NotBlank
        String answer
) {
}