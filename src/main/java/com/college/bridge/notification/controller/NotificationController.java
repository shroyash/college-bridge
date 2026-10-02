package com.college.bridge.notification.controller;

import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.response.ApiResponse;
import com.college.bridge.notification.dto.CreateNotificationRequest;
import com.college.bridge.notification.dto.NotificationInboxResponse;
import com.college.bridge.notification.dto.NotificationResponse;
import com.college.bridge.notification.service.NotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
@Tag(name = "Notifications", description = "Notification dispatch and inbox APIs")
public class NotificationController {

    private final NotificationService notificationService;

    @PostMapping
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN', 'TEACHER')")
    @Operation(summary = "Dispatch a new notification (asynchronous)")
    public ResponseEntity<ApiResponse<NotificationResponse>> createNotification(
            @Valid @RequestBody CreateNotificationRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {

        NotificationResponse response = notificationService.createNotification(request, principal);
        return ResponseEntity.status(HttpStatus.ACCEPTED)
                .body(ApiResponse.success("Notification accepted for delivery", response));
    }

    @GetMapping("/inbox")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Get current user's notification inbox")
    public ResponseEntity<ApiResponse<Page<NotificationInboxResponse>>> getInbox(
            @AuthenticationPrincipal UserPrincipal principal,
            @PageableDefault(size = 20) Pageable pageable) {

        Page<NotificationInboxResponse> inbox = notificationService.getUserInbox(principal, pageable);
        return ResponseEntity.ok(ApiResponse.success("Inbox notifications retrieved successfully", inbox));
    }
}
