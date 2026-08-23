package com.college.bridge.institution.controller;

import com.college.bridge.common.response.ApiResponse;
import com.college.bridge.institution.dto.InstitutionProfileResponse;
import com.college.bridge.institution.dto.UpdateInstitutionProfileRequest;
import com.college.bridge.institution.service.InstitutionAdminService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;

@RestController
@RequestMapping("/api/admin/institution")
@RequiredArgsConstructor
public class InstitutionAdminController {

    private final InstitutionAdminService institutionAdminService;

    @GetMapping("/profile")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<InstitutionProfileResponse>> getProfile(Principal principal) {
        InstitutionProfileResponse response = institutionAdminService.getInstitutionProfile(principal);
        return ResponseEntity.ok(ApiResponse.success("Institution profile fetched successfully.", response));
    }

    @PutMapping("/profile")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<InstitutionProfileResponse>> updateProfile(
            Principal principal,
            @Valid @RequestBody UpdateInstitutionProfileRequest request
    ) {
        InstitutionProfileResponse response = institutionAdminService.updateInstitutionProfile(principal, request);
        return ResponseEntity.ok(ApiResponse.success("Institution profile updated successfully.", response));
    }
}
