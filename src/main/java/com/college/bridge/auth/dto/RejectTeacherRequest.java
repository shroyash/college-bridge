package com.college.bridge.auth.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RejectTeacherRequest {

    @NotBlank(message = "Rejection reason is required")
    private String rejectionReason;
}
