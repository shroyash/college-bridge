package com.college.bridge.institution.controller;

import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.response.ApiResponse;
import com.college.bridge.institution.dto.PendingInstitutionResponse;
import com.college.bridge.institution.dto.RejectInstitutionRequest;
import com.college.bridge.institution.service.SuperAdminInstitutionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/super-admin/institutions")
@RequiredArgsConstructor
@PreAuthorize("hasRole('SUPER_ADMIN')")
public class SuperAdminInstitutionController {

    private final SuperAdminInstitutionService superAdminInstitutionService;

    @GetMapping("/pending")
    public ResponseEntity<ApiResponse<List<PendingInstitutionResponse>>> getPendingInstitutions() {
        List<PendingInstitutionResponse> pending = superAdminInstitutionService.getPendingInstitutions();
        return ResponseEntity.ok(ApiResponse.success("Pending institutions retrieved successfully.", pending));
    }

    @PostMapping("/{id}/approve")
    public ResponseEntity<ApiResponse<Void>> approveInstitution(
            @PathVariable("id") Long id,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        superAdminInstitutionService.approveInstitution(id, principal.getUserId());
        return ResponseEntity.ok(ApiResponse.success("Institution and admin user approved successfully."));
    }

    @PostMapping("/{id}/reject")
    public ResponseEntity<ApiResponse<Void>> rejectInstitution(
            @PathVariable("id") Long id,
            @Valid @RequestBody RejectInstitutionRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        superAdminInstitutionService.rejectInstitution(id, request.getRejectionReason(), principal.getUserId());
        return ResponseEntity.ok(ApiResponse.success("Institution registration rejected successfully."));
    }

    @PostMapping("/{id}/suspend")
    public ResponseEntity<ApiResponse<Void>> suspendInstitution(@PathVariable("id") Long id) {
        superAdminInstitutionService.suspendInstitution(id);
        return ResponseEntity.ok(ApiResponse.success("Institution suspended successfully."));
    }

    @PostMapping("/{id}/reactivate")
    public ResponseEntity<ApiResponse<Void>> reactivateInstitution(@PathVariable("id") Long id) {
        superAdminInstitutionService.reactivateInstitution(id);
        return ResponseEntity.ok(ApiResponse.success("Institution reactivated successfully."));
    }
}
