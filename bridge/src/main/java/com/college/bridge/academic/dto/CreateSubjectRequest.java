package com.college.bridge.academic.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateSubjectRequest {

    @NotNull(message = "Academic level ID is required")
    private Long levelId;

    @NotBlank(message = "Subject name is required")
    @Size(max = 150, message = "Subject name must not exceed 150 characters")
    private String name;

    @Size(max = 50, message = "Subject code must not exceed 50 characters")
    private String code;

    @Min(value = 1, message = "Credit hours must be at least 1")
    @Max(value = 10, message = "Credit hours cannot exceed 10")
    @Builder.Default
    private Integer creditHours = 3;

    @Size(max = 100, message = "FCM Topic ID must not exceed 100 characters")
    private String fcmTopicId;
}
