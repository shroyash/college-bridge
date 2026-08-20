package com.college.bridge.auth.controller;

import com.college.bridge.auth.dto.SendOtpRequest;
import com.college.bridge.auth.dto.VerifyOtpRequest;
import com.college.bridge.auth.entity.OtpType;
import com.college.bridge.auth.service.OtpService;
import com.college.bridge.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/otp")
@RequiredArgsConstructor
public class OtpController {

    private final OtpService otpService;

    @PostMapping("/send")
    public ResponseEntity<ApiResponse<Void>> sendOtp(@Valid @RequestBody SendOtpRequest request) {
        OtpType type = request.getType() != null ? request.getType() : OtpType.VERIFICATION;
        otpService.sendOtp(request.getEmail(), type);
        return ResponseEntity.ok(ApiResponse.success("OTP sent."));
    }

    @PostMapping("/verify")
    public ResponseEntity<ApiResponse<String>> verifyOtp(@Valid @RequestBody VerifyOtpRequest request) {
        OtpType type = request.getType() != null ? request.getType() : OtpType.VERIFICATION;
        String token = otpService.verifyOtp(request.getEmail(), request.getCode(), type);
        return ResponseEntity.ok(ApiResponse.success("OTP verified.", token));
    }
}
