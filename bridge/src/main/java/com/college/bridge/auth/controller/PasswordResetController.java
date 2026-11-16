package com.college.bridge.auth.controller;

import com.college.bridge.auth.dto.*;
import com.college.bridge.auth.service.PasswordResetService;
import com.college.bridge.common.response.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth/password")
public class PasswordResetController {

    private final PasswordResetService passwordResetService;

    public PasswordResetController(PasswordResetService passwordResetService) {
        this.passwordResetService = passwordResetService;
    }

    @PostMapping("/forgot")
    public ResponseEntity<ApiResponse<Void>> forgotPassword(@Valid @RequestBody ForgotPasswordRequest request) {
        passwordResetService.forgotPassword(request);
        return ResponseEntity.ok(ApiResponse.success("If this email is registered, you will receive an OTP shortly."));
    }

    @PostMapping("/verify-otp")
    public ResponseEntity<ApiResponse<OtpVerificationResponse>> verifyOtp(@Valid @RequestBody VerifyOtpRequest request) {
        OtpVerificationResponse response = passwordResetService.verifyOtp(request);
        return ResponseEntity.ok(ApiResponse.success("OTP verified successfully.", response));
    }

    @PostMapping("/resend-otp")
    public ResponseEntity<ApiResponse<Void>> resendOtp(@Valid @RequestBody ForgotPasswordRequest request) {
        passwordResetService.resendOtp(request);
        return ResponseEntity.ok(ApiResponse.success("If this email is registered, a new OTP has been sent."));
    }

    @PostMapping("/reset")
    public ResponseEntity<ApiResponse<Void>> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        passwordResetService.resetPassword(request);
        return ResponseEntity.ok(ApiResponse.success("Password has been reset successfully. Please login again."));
    }
}
