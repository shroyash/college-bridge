package com.college.bridge.verification.dto;

import com.college.bridge.verification.entity.VerificationStatus;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Response DTO representing the current state of a Teacher Verification Request.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VerificationStatusResponse {

    private Long requestId;
    private String applicantName;
    private String applicantEmail;
    private VerificationStatus status;
    private List<String> documentUrls;
    private String rejectionReason;
    private String reviewedByName;
    private LocalDateTime submittedAt;
    private LocalDateTime reviewedAt;
}
