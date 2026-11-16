package com.college.bridge.academic.controller;

import com.college.bridge.academic.dto.AcademicLevelResponse;
import com.college.bridge.academic.dto.AcademicProgramResponse;
import com.college.bridge.academic.service.AcademicAdminService;
import com.college.bridge.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/public/academic")
@RequiredArgsConstructor
public class PublicAcademicController {

    private final AcademicAdminService academicAdminService;

    @GetMapping("/institutions/{code}/programs")
    public ResponseEntity<ApiResponse<List<AcademicProgramResponse>>> getProgramsByInstitutionCode(
            @PathVariable String code
    ) {
        List<AcademicProgramResponse> programs = academicAdminService.getProgramsByInstitutionCode(code);
        return ResponseEntity.ok(ApiResponse.success("Academic programs retrieved successfully.", programs));
    }

    @GetMapping("/programs/{programId}/levels")
    public ResponseEntity<ApiResponse<List<AcademicLevelResponse>>> getLevelsForProgram(
            @PathVariable Long programId
    ) {
        List<AcademicLevelResponse> levels = academicAdminService.getPublicLevelsForProgram(programId);
        return ResponseEntity.ok(ApiResponse.success("Academic levels retrieved successfully.", levels));
    }
}
