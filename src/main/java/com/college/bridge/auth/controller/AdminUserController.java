package com.college.bridge.auth.controller;

import java.security.Principal;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.college.bridge.auth.dto.ChangeRoleRequest;
import com.college.bridge.auth.dto.RejectTeacherRequest;
import com.college.bridge.auth.dto.UserProfileResponse;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.entity.UserStatus;
import com.college.bridge.auth.service.AdminUserService;
import com.college.bridge.common.response.ApiResponse;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminUserController {

    private final AdminUserService adminUserService;

    private String extractEmail(Principal principal) {
        if (principal != null) {
            return principal.getName();
        }
        if (SecurityContextHolder.getContext().getAuthentication() != null) {
            return SecurityContextHolder.getContext().getAuthentication().getName();
        }
        return null;
    }

    @GetMapping("/users")
    public ResponseEntity<ApiResponse<Page<UserProfileResponse>>> getAllUsers(Pageable pageable) {
        Page<UserProfileResponse> page = adminUserService.getAllUsers(pageable);
        return ResponseEntity.ok(ApiResponse.success("Users fetched.", page));
    }

    @GetMapping("/users/search")
    public ResponseEntity<ApiResponse<Page<UserProfileResponse>>> searchUsers(
            @RequestParam String q, Pageable pageable) {
        Page<UserProfileResponse> page = adminUserService.searchUsers(q, pageable);
        return ResponseEntity.ok(ApiResponse.success("Search results.", page));
    }

    @GetMapping("/users/filter")
    public ResponseEntity<ApiResponse<Page<UserProfileResponse>>> filterUsers(
            @RequestParam UserRole role,
            @RequestParam UserStatus status,
            Pageable pageable) {
        Page<UserProfileResponse> page = adminUserService.filterUsers(role, status, pageable);
        return ResponseEntity.ok(ApiResponse.success("Filtered results.", page));
    }

    @PostMapping("/teacher/{id}/verify")
    public ResponseEntity<ApiResponse<Void>> verifyTeacher(
            @PathVariable Long id,
            Principal principal) {
        adminUserService.verifyTeacher(id, extractEmail(principal));
        return ResponseEntity.ok(ApiResponse.success("Teacher verified."));
    }

    @PostMapping("/teacher/{id}/reject")
    public ResponseEntity<ApiResponse<Void>> rejectTeacher(
            @PathVariable Long id,
            @RequestBody RejectTeacherRequest request,
            Principal principal) {
        adminUserService.rejectTeacher(id, request, extractEmail(principal));
        return ResponseEntity.ok(ApiResponse.success("Teacher rejected."));
    }

    @PostMapping("/users/{id}/suspend")
    public ResponseEntity<ApiResponse<Void>> suspendUser(@PathVariable Long id) {
        adminUserService.suspendUser(id);
        return ResponseEntity.ok(ApiResponse.success("User suspended."));
    }

    @PostMapping("/users/{id}/activate")
    public ResponseEntity<ApiResponse<Void>> activateUser(@PathVariable Long id) {
        adminUserService.activateUser(id);
        return ResponseEntity.ok(ApiResponse.success("User activated."));
    }

    @PutMapping("/users/{id}/role")
    public ResponseEntity<ApiResponse<Void>> changeRole(
            @PathVariable Long id,
            @Valid @RequestBody ChangeRoleRequest request,
            Principal principal) {
        adminUserService.changeRole(id, request, extractEmail(principal));
        return ResponseEntity.ok(ApiResponse.success("Role changed."));
    }

    @DeleteMapping("/users/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteUser(@PathVariable Long id) {
        adminUserService.deleteUser(id);
        return ResponseEntity.ok(ApiResponse.success("User deleted."));
    }
}
