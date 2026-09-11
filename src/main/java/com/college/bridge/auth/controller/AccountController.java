package com.college.bridge.auth.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
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
import com.college.bridge.auth.security.UserPrincipal;
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
    public ResponseEntity<ApiResponse<UserProfileResponse>> getProfile(
            @AuthenticationPrincipal UserPrincipal principal) {

        UserProfileResponse profile =
                accountService.getProfile(principal.getUserId());

        return ResponseEntity.ok(
                ApiResponse.success("Profile fetched.", profile)
        );
    }

    @PutMapping("/profile")
    public ResponseEntity<ApiResponse<UserProfileResponse>> updateProfile(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody UpdateProfileRequest request) {

        UserProfileResponse updated =
                accountService.updateProfile(
                        principal.getUserId(),
                        request
                );

        return ResponseEntity.ok(
                ApiResponse.success("Profile updated.", updated)
        );
    }

    @PostMapping("/password/change")
    public ResponseEntity<ApiResponse<Void>> changePassword(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody ChangePasswordRequest request) {

        accountService.changePassword(
                principal.getUserId(),
                request
        );

        return ResponseEntity.ok(
                ApiResponse.success("Password changed.")
        );
    }

    @PostMapping("/email/initiate")
    public ResponseEntity<ApiResponse<Void>> initiateEmailChange(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody InitiateEmailChangeRequest request) {

        accountService.initiateEmailChange(
                principal.getUserId(),
                request
        );

        return ResponseEntity.ok(
                ApiResponse.success(
                        "Email change initiated. An OTP has been sent to your new email."
                )
        );
    }

    @PostMapping("/email/confirm")
    public ResponseEntity<ApiResponse<Void>> confirmEmailChange(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody ConfirmEmailChangeRequest request) {

        accountService.confirmEmailChange(
                principal.getUserId(),
                request
        );

        return ResponseEntity.ok(
                ApiResponse.success(
                        "Email changed successfully. Please login again."
                )
        );
    }

    @PostMapping("/profile/image")
    public ResponseEntity<ApiResponse<String>> uploadProfileImage(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam("file") MultipartFile file) {

        String url =
                accountService.uploadProfileImage(
                        principal.getUserId(),
                        file
                );

        return ResponseEntity.ok(
                ApiResponse.success("Profile image uploaded.", url)
        );
    }

    @DeleteMapping
    public ResponseEntity<ApiResponse<Void>> deleteOwnAccount(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestBody(required = false) Map<String, String> body) {

        String password =
                body != null ? body.get("password") : null;

        accountService.deleteOwnAccount(
                principal.getUserId(),
                password
        );

        return ResponseEntity.ok(
                ApiResponse.success("Account deleted.")
        );
    }
}