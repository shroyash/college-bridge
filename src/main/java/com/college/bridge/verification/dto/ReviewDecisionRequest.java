package com.college.bridge.verification.dto;

import lombok.*;

/**
 * Payload sent by an admin when rejecting a Teacher Verification Request.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReviewDecisionRequest {

    /** Required when rejecting; explains why the request was denied. */
    private String rejectionReason;
}
