package com.college.bridge.verification.dto;

import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.util.List;

/**
 * Payload sent by a user when submitting a Teacher Verification Request.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SubmitVerificationRequest {

    /**
     * List of publicly accessible document URLs evidencing the applicant's
     * teaching credentials (e.g. licence, employment letter, certificates).
     * At least one document is required.
     */
    @NotNull(message = "At least one document URL is required")
    private List<String> documentUrls;
}
