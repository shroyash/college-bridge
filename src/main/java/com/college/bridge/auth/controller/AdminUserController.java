package com.college.bridge.auth.controller;

import java.security.Principal;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
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

import com.college.bridge.auth.dto.BulkTransferRequest;
import com.college.bridge.auth.dto.BulkTransferResponse;
import com.college.bridge.auth.dto.ChangeRoleRequest;
import com.college.bridge.auth.dto.StudentFilterOptionsResponse;
import com.college.bridge.auth.dto.UserProfileResponse;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.entity.UserStatus;
import com.college.bridge.auth.service.AdminUserService;
import com.college.bridge.common.response.ApiResponse;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

import com.college.bridge.auth.service.StudentCohortService;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
public class AdminUserController {

    private final AdminUserService adminUserService;
    private final StudentCohortService studentCohortService;

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

    @GetMapping("/students")
    public ResponseEntity<ApiResponse<Page<UserProfileResponse>>> getStudents(
            @RequestParam(required = false) Long programId,
            @RequestParam(required = false) Long levelId,
            @RequestParam(required = false) String search,
            Pageable pageable,
            Principal principal) {
        Page<UserProfileResponse> page = studentCohortService.getStudentsFiltered(principal, programId, levelId, search, pageable);
        return ResponseEntity.ok(ApiResponse.success("Students fetched successfully.", page));
    }

    @GetMapping("/students/filter-options")
    public ResponseEntity<ApiResponse<StudentFilterOptionsResponse>> getStudentFilterOptions(Principal principal) {
        StudentFilterOptionsResponse options = studentCohortService.getStudentFilterOptions(principal);
        return ResponseEntity.ok(ApiResponse.success("Student filter options fetched.", options));
    }

    @PostMapping("/students/bulk-transfer")
    public ResponseEntity<ApiResponse<BulkTransferResponse>> bulkTransferStudents(
            @Valid @RequestBody BulkTransferRequest request,
            Principal principal) {
        BulkTransferResponse response = studentCohortService.bulkTransferStudents(principal, request);
        return ResponseEntity.ok(ApiResponse.success(
                response.getUpdatedStudents() + " students successfully updated.",
                response
        ));
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
            @RequestBody ChangeRoleRequest request,
            Principal principal) {
        adminUserService.changeRole(id, request, extractEmail(principal));
        return ResponseEntity.ok(ApiResponse.success("User role updated."));
    }

    @DeleteMapping("/users/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteUser(@PathVariable Long id) {
        adminUserService.deleteUser(id);
        return ResponseEntity.ok(ApiResponse.success("User deleted."));
    }
}
