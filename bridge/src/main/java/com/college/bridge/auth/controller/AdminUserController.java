package com.college.bridge.auth.controller;

import com.college.bridge.auth.dto.ChangeRoleRequest;
import com.college.bridge.auth.dto.UserProfileResponse;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.entity.UserStatus;
import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.auth.service.AdminUserService;
import com.college.bridge.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/users")
@RequiredArgsConstructor
public class AdminUserController {

    private final AdminUserService adminUserService;

    @GetMapping
    public ResponseEntity<ApiResponse<Page<UserProfileResponse>>> getAllUsers(
            Pageable pageable
    ) {
        Page<UserProfileResponse> page = adminUserService.getAllUsers(pageable);
        return ResponseEntity.ok(ApiResponse.success("Users fetched.", page));
    }

    @GetMapping("/search")
    public ResponseEntity<ApiResponse<Page<UserProfileResponse>>> searchUsers(
            @RequestParam String q,
            Pageable pageable
    ) {
        Page<UserProfileResponse> page = adminUserService.searchUsers(q, pageable);
        return ResponseEntity.ok(ApiResponse.success("Search results.", page));
    }

    @GetMapping("/filter")
    public ResponseEntity<ApiResponse<Page<UserProfileResponse>>> filterUsers(
            @RequestParam UserRole role,
            @RequestParam UserStatus status,
            Pageable pageable
    ) {
        Page<UserProfileResponse> page = adminUserService.filterUsers(role, status, pageable);
        return ResponseEntity.ok(ApiResponse.success("Filtered results.", page));
    }

    @PostMapping("/{id}/suspend")
    public ResponseEntity<ApiResponse<Void>> suspendUser(
            @PathVariable Long id
    ) {
        adminUserService.suspendUser(id);
        return ResponseEntity.ok(ApiResponse.success("User suspended."));
    }

    @PostMapping("/{id}/activate")
    public ResponseEntity<ApiResponse<Void>> activateUser(
            @PathVariable Long id
    ) {
        adminUserService.activateUser(id);
        return ResponseEntity.ok(ApiResponse.success("User activated."));
    }

    @PutMapping("/{id}/role")
    public ResponseEntity<ApiResponse<Void>> changeRole(
            @PathVariable Long id,
            @Valid @RequestBody ChangeRoleRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        adminUserService.changeRole(id, request, principal.getUsername());
        return ResponseEntity.ok(ApiResponse.success("User role updated."));
    }

}