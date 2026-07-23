package com.college.bridge.auth.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.college.bridge.auth.dto.ChangePasswordRequest;
import com.college.bridge.auth.dto.ConfirmEmailChangeRequest;
import com.college.bridge.auth.dto.InitiateEmailChangeRequest;
import com.college.bridge.auth.dto.UpdateProfileRequest;
import com.college.bridge.auth.dto.UserProfileResponse;
import com.college.bridge.auth.service.AccountService;
import com.college.bridge.common.response.ApiResponse;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/account")
@RequiredArgsConstructor
public class AccountController {

    private final AccountService accountService;

    @GetMapping("/profile")
    public ResponseEntity<ApiResponse<UserProfileResponse>> getProfile(@RequestHeader("X-User-Email") String email) {
        UserProfileResponse profile = accountService.getProfile(email);
        return ResponseEntity.ok(ApiResponse.success("Profile fetched.", profile));
    }

    @PutMapping("/profile")
    public ResponseEntity<ApiResponse<UserProfileResponse>> updateProfile(@RequestHeader("X-User-Email") String email, @Valid @RequestBody UpdateProfileRequest request) {
        UserProfileResponse updated = accountService.updateProfile(email, request);
        return ResponseEntity.ok(ApiResponse.success("Profile updated.", updated));
    }

    @PostMapping("/password/change")
    public ResponseEntity<ApiResponse<Void>> changePassword(@RequestHeader("X-User-Email") String email, @Valid @RequestBody ChangePasswordRequest request) {
        accountService.changePassword(email, request);
        return ResponseEntity.ok(ApiResponse.success("Password changed."));
    }

    @PostMapping("/email/initiate")
    public ResponseEntity<ApiResponse<Void>> initiateEmailChange(@RequestHeader("X-User-Email") String email, @Valid @RequestBody InitiateEmailChangeRequest request) {
        accountService.initiateEmailChange(email, request);
        return ResponseEntity.ok(ApiResponse.success("Email change initiated."));
    }

    @PostMapping("/email/confirm")
    public ResponseEntity<ApiResponse<Void>> confirmEmailChange(@RequestHeader("X-User-Email") String email, @Valid @RequestBody ConfirmEmailChangeRequest request) {
        accountService.confirmEmailChange(email, request);
        return ResponseEntity.ok(ApiResponse.success("Email changed."));
    }

    @PostMapping("/profile/image")
    public ResponseEntity<ApiResponse<String>> uploadProfileImage(@RequestHeader("X-User-Email") String email, @RequestParam("file") MultipartFile file) {
        String url = accountService.uploadProfileImage(email, file);
        return ResponseEntity.ok(ApiResponse.success("Image uploaded.", url));
    }

    @DeleteMapping
    public ResponseEntity<ApiResponse<Void>> deleteOwnAccount(@RequestHeader("X-User-Email") String email, @RequestBody Map<String, String> body) {
        String password = body.get("password");
        accountService.deleteOwnAccount(email, password);
        return ResponseEntity.ok(ApiResponse.success("Account deleted."));
    }
}

