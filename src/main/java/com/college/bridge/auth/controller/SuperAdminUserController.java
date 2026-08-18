package com.college.bridge.auth.controller;

import com.college.bridge.auth.dto.SuperAdminUserResponse;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.entity.UserStatus;
import com.college.bridge.auth.service.SuperAdminUserService;
import com.college.bridge.common.response.ApiResponse;
import com.college.bridge.common.response.PageResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/super-admin")
@RequiredArgsConstructor
@PreAuthorize("hasRole('SUPER_ADMIN')")
public class SuperAdminUserController {

    private final SuperAdminUserService superAdminUserService;

    @GetMapping("/users")
    public ResponseEntity<ApiResponse<PageResponse<SuperAdminUserResponse>>> getUsers(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) UserRole role,
            @RequestParam(required = false) UserStatus status,
            @RequestParam(required = false) Long institutionId,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable
    ) {
        PageResponse<SuperAdminUserResponse> result = superAdminUserService.getUsers(pageable, search, role, status, institutionId);
        return ResponseEntity.ok(ApiResponse.success("Users retrieved successfully.", result));
    }

    @GetMapping("/admins")
    public ResponseEntity<ApiResponse<PageResponse<SuperAdminUserResponse>>> getAdmins(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) UserStatus status,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable
    ) {
        PageResponse<SuperAdminUserResponse> result = superAdminUserService.getAdmins(pageable, search, status);
        return ResponseEntity.ok(ApiResponse.success("Admin users retrieved successfully.", result));
    }
}
