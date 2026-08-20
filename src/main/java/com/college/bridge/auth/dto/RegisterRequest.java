package com.college.bridge.auth.dto;

import jakarta.validation.constraints.*;
import lombok.*;

/**
 * Registration payload accepted from the frontend.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RegisterRequest {

    @NotBlank(message = "Institution code is required")
    private String institutionCode;

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

    @NotBlank(message = "Faculty is required")
    @Size(max = 20, message = "Faculty must not exceed 20 characters")
    @Pattern(regexp = "^[A-Z0-9_]{2,20}$", message = "Faculty must be 2-20 uppercase alphanumeric characters or underscores")
    private String faculty;

    @NotNull(message = "Semester is required")
    @Min(value = 1, message = "Semester must be at least 1")
    @Max(value = 8, message = "Semester must not exceed 8")
    private Integer semester;
}
