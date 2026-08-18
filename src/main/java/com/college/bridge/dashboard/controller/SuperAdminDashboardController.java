package com.college.bridge.dashboard.controller;

import com.college.bridge.common.response.ApiResponse;
import com.college.bridge.dashboard.service.SuperAdminDashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/super-admin/dashboard")
@RequiredArgsConstructor
@PreAuthorize("hasRole('SUPER_ADMIN')")
public class SuperAdminDashboardController {

    private final SuperAdminDashboardService dashboardService;

    @GetMapping("/institutions/total")
    public ResponseEntity<ApiResponse<Long>> getTotalInstitutions() {
        return ResponseEntity.ok(ApiResponse.success("Total institutions count.", dashboardService.getTotalInstitutions()));
    }

    @GetMapping("/institutions/pending")
    public ResponseEntity<ApiResponse<Long>> getPendingInstitutions() {
        return ResponseEntity.ok(ApiResponse.success("Pending institutions count.", dashboardService.getPendingInstitutions()));
    }

    @GetMapping("/institutions/active")
    public ResponseEntity<ApiResponse<Long>> getActiveInstitutions() {
        return ResponseEntity.ok(ApiResponse.success("Active institutions count.", dashboardService.getActiveInstitutions()));
    }

    @GetMapping("/institutions/suspended")
    public ResponseEntity<ApiResponse<Long>> getSuspendedInstitutions() {
        return ResponseEntity.ok(ApiResponse.success("Suspended institutions count.", dashboardService.getSuspendedInstitutions()));
    }

    @GetMapping("/users/total")
    public ResponseEntity<ApiResponse<Long>> getTotalUsers() {
        return ResponseEntity.ok(ApiResponse.success("Total users count.", dashboardService.getTotalUsers()));
    }

    @GetMapping("/users/students")
    public ResponseEntity<ApiResponse<Long>> getTotalStudents() {
        return ResponseEntity.ok(ApiResponse.success("Total students count.", dashboardService.getTotalStudents()));
    }

    @GetMapping("/users/teachers")
    public ResponseEntity<ApiResponse<Long>> getTotalTeachers() {
        return ResponseEntity.ok(ApiResponse.success("Total teachers count.", dashboardService.getTotalTeachers()));
    }

    @GetMapping("/users/admins")
    public ResponseEntity<ApiResponse<Long>> getTotalAdmins() {
        return ResponseEntity.ok(ApiResponse.success("Total admins count.", dashboardService.getTotalAdmins()));
    }
}
