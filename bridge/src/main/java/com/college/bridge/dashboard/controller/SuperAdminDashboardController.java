package com.college.bridge.dashboard.controller;

import com.college.bridge.common.response.ApiResponse;
import com.college.bridge.dashboard.dto.SuperAdminDashboardResponse;
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
public class SuperAdminDashboardController {

    private final SuperAdminDashboardService dashboardService;

    @GetMapping
    public ResponseEntity<ApiResponse<SuperAdminDashboardResponse>> getDashboard() {

        return ResponseEntity.ok(
                ApiResponse.success(
                        "Dashboard statistics fetched successfully.",
                        dashboardService.getDashboard()
                )
        );
    }

}
