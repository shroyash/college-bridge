package com.college.bridge.academic.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
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

    @NotBlank(message = "Subject name is required")
    private String name;

    @NotBlank(message = "Faculty is required")
    @Size(max = 20, message = "Faculty must not exceed 20 characters")
    @Pattern(regexp = "^[A-Z0-9_]{2,20}$", message = "Faculty must be 2-20 uppercase alphanumeric characters or underscores")
    private String faculty;

    @NotNull(message = "Semester is required")
    @Min(value = 1, message = "Semester must be at least 1")
    @Max(value = 12, message = "Semester cannot exceed 12")
    private Integer semester;

    @Min(value = 1, message = "Credit hours must be at least 1")
    @Max(value = 10, message = "Credit hours cannot exceed 10")
    @Builder.Default
    private Integer creditHours = 3;
}
