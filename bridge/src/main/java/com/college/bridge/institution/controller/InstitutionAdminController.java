package com.college.bridge.institution.controller;

import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.response.ApiResponse;
import com.college.bridge.institution.dto.InstitutionProfileResponse;
import com.college.bridge.institution.dto.UpdateInstitutionProfileRequest;
import com.college.bridge.institution.service.InstitutionAdminService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/institution")
@RequiredArgsConstructor
public class InstitutionAdminController {

    private final InstitutionAdminService institutionAdminService;

    @GetMapping("/profile")
    public ResponseEntity<ApiResponse<InstitutionProfileResponse>> getProfile(
            @AuthenticationPrincipal UserPrincipal principal
    ) {

        InstitutionProfileResponse response =
                institutionAdminService.getInstitutionProfile(principal);

        return ResponseEntity.ok(
                ApiResponse.success(
                        "Institution profile fetched successfully.",
                        response
                )
        );
    }

    @PutMapping("/profile")
    public ResponseEntity<ApiResponse<InstitutionProfileResponse>> updateProfile(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody UpdateInstitutionProfileRequest request
    ) {

        InstitutionProfileResponse response =
                institutionAdminService.updateInstitutionProfile(
                        principal,
                        request
                );

        return ResponseEntity.ok(
                ApiResponse.success(
                        "Institution profile updated successfully.",
                        response
                )
        );
    }
}