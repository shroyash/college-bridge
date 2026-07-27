package com.college.bridge.auth.controller;

import java.security.Principal;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
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

    private String extractEmail(Principal principal) {
        if (principal != null) {
            return principal.getName();
        }
        if (SecurityContextHolder.getContext().getAuthentication() != null) {
            return SecurityContextHolder.getContext().getAuthentication().getName();
        }
        return null;
    }

    @GetMapping("/profile")
    public ResponseEntity<ApiResponse<UserProfileResponse>> getProfile(Principal principal) {
        String email = extractEmail(principal);
        UserProfileResponse profile = accountService.getProfile(email);
        return ResponseEntity.ok(ApiResponse.success("Profile fetched.", profile));
    }

    @PutMapping("/profile")
    public ResponseEntity<ApiResponse<UserProfileResponse>> updateProfile(
            Principal principal,
            @Valid @RequestBody UpdateProfileRequest request) {
        String email = extractEmail(principal);
        UserProfileResponse updated = accountService.updateProfile(email, request);
        return ResponseEntity.ok(ApiResponse.success("Profile updated.", updated));
    }

    @PostMapping("/password/change")
    public ResponseEntity<ApiResponse<Void>> changePassword(
            Principal principal,
            @Valid @RequestBody ChangePasswordRequest request) {
        String email = extractEmail(principal);
        accountService.changePassword(email, request);
        return ResponseEntity.ok(ApiResponse.success("Password changed."));
    }

    @PostMapping("/email/initiate")
    public ResponseEntity<ApiResponse<Void>> initiateEmailChange(
            Principal principal,
            @Valid @RequestBody InitiateEmailChangeRequest request) {
        String email = extractEmail(principal);
        accountService.initiateEmailChange(email, request);
        return ResponseEntity.ok(ApiResponse.success("Email change initiated. An OTP has been sent to your new email."));
    }

    @PostMapping("/email/confirm")
    public ResponseEntity<ApiResponse<Void>> confirmEmailChange(
            Principal principal,
            @Valid @RequestBody ConfirmEmailChangeRequest request) {
        String email = extractEmail(principal);
        accountService.confirmEmailChange(email, request);
        return ResponseEntity.ok(ApiResponse.success("Email changed successfully. Please login again."));
    }

    @PostMapping("/profile/image")
    public ResponseEntity<ApiResponse<String>> uploadProfileImage(
            Principal principal,
            @RequestParam("file") MultipartFile file) {
        String email = extractEmail(principal);
        String url = accountService.uploadProfileImage(email, file);
        return ResponseEntity.ok(ApiResponse.success("Profile image uploaded.", url));
    }

    @DeleteMapping
    public ResponseEntity<ApiResponse<Void>> deleteOwnAccount(
            Principal principal,
            @RequestBody(required = false) Map<String, String> body) {
        String email = extractEmail(principal);
        String password = (body != null) ? body.get("password") : null;
        accountService.deleteOwnAccount(email, password);
        return ResponseEntity.ok(ApiResponse.success("Account deleted."));
    }
}
