package com.college.bridge.doubt.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record CreateDoubtRequest(

        @NotNull
        Long subjectId,

        @NotBlank
        String question
) {
}