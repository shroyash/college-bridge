package com.college.bridge.clazz.dto;

import jakarta.validation.constraints.NotNull;
import lombok.*;

/**
 * Payload for assigning a teacher to a class (admin only).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AssignTeacherRequest {

    @NotNull(message = "Teacher ID is required")
    private Long teacherId;
}
