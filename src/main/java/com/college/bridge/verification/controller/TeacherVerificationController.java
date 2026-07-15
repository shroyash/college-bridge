package com.college.bridge.verification.controller;

import com.college.bridge.auth.security.CustomUserDetails;
import com.college.bridge.common.response.ApiResponse;
import com.college.bridge.verification.dto.ReviewDecisionRequest;
import com.college.bridge.verification.dto.SubmitVerificationRequest;
import com.college.bridge.verification.dto.VerificationStatusResponse;
import com.college.bridge.verification.service.TeacherVerificationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Teacher Verification REST API.
 * <p>
 * Student-facing:
 *   POST   /api/verification/submit           — submit request with doc URLs
 *   GET    /api/verification/my-request       — check own request status
 *
 * Admin-facing (/api/admin/**):
 *   GET    /api/admin/verification/pending    — list all pending requests
 *   POST   /api/admin/verification/{id}/approve — approve request
 *   POST   /api/admin/verification/{id}/reject  — reject with reason
 */
@RestController
@RequiredArgsConstructor
public class TeacherVerificationController {

    private final TeacherVerificationService verificationService;

    // =========================================================================
    // Student endpoints
    // =========================================================================

    @PostMapping("/api/verification/submit")
    public ResponseEntity<ApiResponse<VerificationStatusResponse>> submitRequest(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody SubmitVerificationRequest request
    ) {
        VerificationStatusResponse response = verificationService.submitRequest(
                userDetails.getUser().getUserId(), request);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("Teacher verification request submitted successfully.", response));
    }

    @GetMapping("/api/verification/my-request")
    public ResponseEntity<ApiResponse<VerificationStatusResponse>> getMyRequest(
            @AuthenticationPrincipal CustomUserDetails userDetails
    ) {
        VerificationStatusResponse response = verificationService.getMyRequest(
                userDetails.getUser().getUserId());
        return ResponseEntity.ok(ApiResponse.success("Verification request retrieved.", response));
    }

    // =========================================================================
    // Admin endpoints
    // =========================================================================

    @GetMapping("/api/admin/verification/pending")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<List<VerificationStatusResponse>>> getPendingRequests() {
        List<VerificationStatusResponse> pending = verificationService.getPendingRequests();
        return ResponseEntity.ok(ApiResponse.success(
                "Pending verification requests retrieved.", pending));
    }

    @PostMapping("/api/admin/verification/{requestId}/approve")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<VerificationStatusResponse>> approveRequest(
            @AuthenticationPrincipal CustomUserDetails adminDetails,
            @PathVariable Long requestId
    ) {
        VerificationStatusResponse response = verificationService.approveRequest(
                adminDetails.getUser().getUserId(), requestId);
        return ResponseEntity.ok(ApiResponse.success(
                "Teacher verification request approved. User has been promoted to ROLE_TEACHER.", response));
    }

    @PostMapping("/api/admin/verification/{requestId}/reject")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<VerificationStatusResponse>> rejectRequest(
            @AuthenticationPrincipal CustomUserDetails adminDetails,
            @PathVariable Long requestId,
            @RequestBody ReviewDecisionRequest decisionRequest
    ) {
        VerificationStatusResponse response = verificationService.rejectRequest(
                adminDetails.getUser().getUserId(), requestId, decisionRequest);
        return ResponseEntity.ok(ApiResponse.success("Teacher verification request rejected.", response));
    }
}
