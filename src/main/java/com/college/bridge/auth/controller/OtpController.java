package com.college.bridge.auth.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.college.bridge.auth.entity.OtpType;
import com.college.bridge.auth.service.OtpService;
import com.college.bridge.common.response.ApiResponse;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/otp")
@RequiredArgsConstructor
public class OtpController {

    private final OtpService otpService;

    @PostMapping("/send")
    public ResponseEntity<ApiResponse<Void>> sendOtp(@RequestBody Map<String, String> body) {
        String email = body.get("email");
        OtpType type = OtpType.valueOf(body.getOrDefault("type", "VERIFICATION"));
        otpService.sendOtp(email, type);
        return ResponseEntity.ok(ApiResponse.success("OTP sent."));
    }

    @PostMapping("/verify")
    public ResponseEntity<ApiResponse<String>> verifyOtp(@RequestBody Map<String, String> body) {
        String email = body.get("email");
        String code = body.get("code");
        OtpType type = OtpType.valueOf(body.getOrDefault("type", "VERIFICATION"));
        String token = otpService.verifyOtp(email, code, type);
        return ResponseEntity.ok(ApiResponse.success("OTP verified.", token));
    }

    @PostMapping("/validate")
    public ResponseEntity<ApiResponse<Boolean>> validate(@RequestBody Map<String, String> body) {
        String email = body.get("email");
        String token = body.get("token");
        OtpType type = OtpType.valueOf(body.getOrDefault("type", "VERIFICATION"));
        boolean ok = otpService.validateVerificationToken(email, token, type);
        return ResponseEntity.ok(ApiResponse.success("Validation result.", ok));
    }
}
