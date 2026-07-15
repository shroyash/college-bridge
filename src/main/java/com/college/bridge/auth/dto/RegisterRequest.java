package com.college.bridge.auth.dto;

import com.college.bridge.academic.entity.Faculty;
import jakarta.validation.constraints.*;
import lombok.*;

/**
 * Registration payload accepted from the frontend.
 * <p>
 * The {@code role} field is intentionally absent — the backend exclusively
 * assigns {@code ROLE_STUDENT} on registration. Teacher promotion goes through
 * the Teacher Verification workflow.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RegisterRequest {

    @NotBlank(message = "Name is required")
    @Size(max = 100, message = "Name must not exceed 100 characters")
    private String name;

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    @Size(max = 150, message = "Email must not exceed 150 characters")
    private String email;

    @NotBlank(message = "Password is required")
    @Size(min = 6, max = 100, message = "Password must be at least 6 characters")
    private String password;

    @NotNull(message = "Faculty is required")
    private Faculty faculty;

    @NotNull(message = "Semester is required")
    @Min(value = 1, message = "Semester must be at least 1")
    @Max(value = 8, message = "Semester must not exceed 8")
    private Integer semester;
}

