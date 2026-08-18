package com.college.bridge.institution.controller;

import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.response.ApiResponse;
import com.college.bridge.common.response.PageResponse;
import com.college.bridge.institution.dto.*;
import com.college.bridge.institution.entity.InstitutionStatus;
import com.college.bridge.institution.service.SuperAdminInstitutionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/super-admin/institutions")
@RequiredArgsConstructor
@PreAuthorize("hasRole('SUPER_ADMIN')")
public class SuperAdminInstitutionController {

    private final SuperAdminInstitutionService superAdminInstitutionService;

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<SuperAdminInstitutionResponse>>> getAllInstitutions(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) InstitutionStatus status,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable
    ) {
        PageResponse<SuperAdminInstitutionResponse> page = superAdminInstitutionService.getAllInstitutions(pageable, search, status);
        return ResponseEntity.ok(ApiResponse.success("Institutions retrieved successfully.", page));
    }

    @GetMapping("/pending")
    public ResponseEntity<ApiResponse<PageResponse<SuperAdminPendingInstitutionResponse>>> getPendingInstitutions(
            @RequestParam(required = false) String search,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable
    ) {
        PageResponse<SuperAdminPendingInstitutionResponse> pending = superAdminInstitutionService.getPendingInstitutionsPaginated(pageable, search);
        return ResponseEntity.ok(ApiResponse.success("Pending institutions retrieved successfully.", pending));
    }

    @PostMapping("/{id}/approve")
    public ResponseEntity<ApiResponse<Void>> approveInstitution(
            @PathVariable("id") Long id,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        superAdminInstitutionService.approveInstitution(id, principal != null ? principal.getUserId() : 1L);
        return ResponseEntity.ok(ApiResponse.success("Institution and admin user approved successfully."));
    }

    @PostMapping("/{id}/reject")
    public ResponseEntity<ApiResponse<Void>> rejectInstitution(
            @PathVariable("id") Long id,
            @Valid @RequestBody RejectInstitutionRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        superAdminInstitutionService.rejectInstitution(id, request.getRejectionReason(), principal != null ? principal.getUserId() : 1L);
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
