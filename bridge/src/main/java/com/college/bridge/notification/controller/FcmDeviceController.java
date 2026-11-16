package com.college.bridge.notification.controller;

import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.response.ApiResponse;
import com.college.bridge.notification.dto.RegisterDeviceRequest;
import com.college.bridge.notification.service.FcmDeviceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/devices")
@RequiredArgsConstructor
@Tag(name = "FCM Devices", description = "Device token management for push notifications")
public class FcmDeviceController {

    private final FcmDeviceService fcmDeviceService;

    @PostMapping("/fcm-token")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Register or refresh an FCM device token")
    public ResponseEntity<ApiResponse<Void>> registerDevice(
            @Valid @RequestBody RegisterDeviceRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {

        fcmDeviceService.registerDevice(request, principal);
        return ResponseEntity.ok(ApiResponse.success("Device token registered successfully"));
    }

    @DeleteMapping("/fcm-token")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Deactivate an FCM device token on logout")
    public ResponseEntity<ApiResponse<Void>> deactivateDevice(
            @RequestParam("token") String token,
            @AuthenticationPrincipal UserPrincipal principal) {

        fcmDeviceService.deactivateDevice(token, principal);
        return ResponseEntity.ok(ApiResponse.success("Device token deactivated successfully"));
    }
}
