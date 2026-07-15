package com.college.bridge.clazz.dto;

import com.college.bridge.academic.entity.Faculty;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.*;

/**
 * Payload for creating a new academic class (admin only).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateClassRequest {

    @NotNull(message = "Faculty is required")
    private Faculty faculty;

    @NotNull(message = "Semester is required")
    @Min(value = 1, message = "Semester must be at least 1")
    @Max(value = 8, message = "Semester must not exceed 8")
    private Integer semester;

    /** Optional subject limit — if omitted, the class covers all semester subjects. */
    private Long subjectId;
}
