package com.college.bridge.academic.dto;

import com.college.bridge.academic.entity.AcademicLevelType;
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
public class AcademicLevelRequest {

    @NotBlank(message = "Level name is required")
    @Size(max = 100, message = "Name must not exceed 100 characters")
    private String name;

    @NotNull(message = "Level number is required")
    @Min(value = 1, message = "Level number must be at least 1")
    private Integer levelNumber;

    @NotNull(message = "Level type is required")
    private AcademicLevelType type;
}
