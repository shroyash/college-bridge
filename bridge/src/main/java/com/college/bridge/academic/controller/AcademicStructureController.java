package com.college.bridge.academic.controller;

import com.college.bridge.academic.dto.*;
import com.college.bridge.academic.service.AcademicAdminService;
import com.college.bridge.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/academic")
@RequiredArgsConstructor
public class AcademicStructureController {

    private final AcademicAdminService academicAdminService;

    // --- PROGRAM ENDPOINTS ---

    @PostMapping("/programs")
    public ResponseEntity<ApiResponse<AcademicProgramResponse>> createProgram(
            @Valid @RequestBody AcademicProgramRequest request
    ) {
        AcademicProgramResponse response = academicAdminService.createProgram(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Academic program created successfully.", response));
    }

    @GetMapping("/programs")
    public ResponseEntity<ApiResponse<List<AcademicProgramResponse>>> getPrograms() {
        List<AcademicProgramResponse> programs = academicAdminService.getPrograms();
        return ResponseEntity.ok(ApiResponse.success("Academic programs retrieved.", programs));
    }

    @GetMapping("/programs/{programId}")
    public ResponseEntity<ApiResponse<AcademicProgramResponse>> getProgramById(@PathVariable Long programId) {
        AcademicProgramResponse program = academicAdminService.getProgramById(programId);
        return ResponseEntity.ok(ApiResponse.success("Academic program retrieved.", program));
    }

    @PutMapping("/programs/{programId}")
    public ResponseEntity<ApiResponse<AcademicProgramResponse>> updateProgram(
            @PathVariable Long programId,
            @Valid @RequestBody AcademicProgramRequest request
    ) {
        AcademicProgramResponse response = academicAdminService.updateProgram(programId, request);
        return ResponseEntity.ok(ApiResponse.success("Academic program updated successfully.", response));
    }

    @DeleteMapping("/programs/{programId}")
    public ResponseEntity<ApiResponse<Void>> deleteProgram(@PathVariable Long programId) {
        academicAdminService.deleteProgram(programId);
        return ResponseEntity.ok(ApiResponse.success("Academic program deleted successfully."));
    }

    // --- LEVEL ENDPOINTS ---

    @PostMapping("/programs/{programId}/levels")
    public ResponseEntity<ApiResponse<AcademicLevelResponse>> createLevel(
            @PathVariable Long programId,
            @Valid @RequestBody AcademicLevelRequest request
    ) {
        AcademicLevelResponse response = academicAdminService.createLevel(programId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Academic level created successfully.", response));
    }

    @GetMapping("/programs/{programId}/levels")
    public ResponseEntity<ApiResponse<List<AcademicLevelResponse>>> getLevelsForProgram(@PathVariable Long programId) {
        List<AcademicLevelResponse> levels = academicAdminService.getLevelsForProgram(programId);
        return ResponseEntity.ok(ApiResponse.success("Academic levels retrieved.", levels));
    }

    @GetMapping("/levels")
    public ResponseEntity<ApiResponse<List<AcademicLevelResponse>>> getAllLevels() {
        List<AcademicLevelResponse> levels = academicAdminService.getAllLevelsForInstitution();
        return ResponseEntity.ok(ApiResponse.success("Academic levels retrieved.", levels));
    }

    @PutMapping("/levels/{levelId}")
    public ResponseEntity<ApiResponse<AcademicLevelResponse>> updateLevel(
            @PathVariable Long levelId,
            @Valid @RequestBody AcademicLevelRequest request
    ) {
        AcademicLevelResponse response = academicAdminService.updateLevel(levelId, request);
        return ResponseEntity.ok(ApiResponse.success("Academic level updated successfully.", response));
    }

    @DeleteMapping("/levels/{levelId}")
    public ResponseEntity<ApiResponse<Void>> deleteLevel(@PathVariable Long levelId) {
        academicAdminService.deleteLevel(levelId);
        return ResponseEntity.ok(ApiResponse.success("Academic level deleted successfully."));
    }

    // --- SUBJECT ENDPOINTS ---

    @PostMapping("/subjects")
    public ResponseEntity<ApiResponse<SubjectResponse>> createSubject(
            @Valid @RequestBody CreateSubjectRequest request
    ) {
        SubjectResponse response = academicAdminService.createSubject(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Subject created successfully.", response));
    }

    @PostMapping("/subjects/batch")
    public ResponseEntity<ApiResponse<List<SubjectResponse>>> batchCreateSubjects(
            @Valid @RequestBody BatchCreateSubjectRequest request
    ) {
        List<SubjectResponse> responses = academicAdminService.batchCreateSubjects(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Subjects batch created successfully.", responses));
    }

    @GetMapping("/subjects")
    public ResponseEntity<ApiResponse<List<SubjectResponse>>> getSubjects(
            @RequestParam(required = false) Long levelId
    ) {
        List<SubjectResponse> subjects;
        if (levelId != null) {
            subjects = academicAdminService.getSubjectsForLevel(levelId);
        } else {
            subjects = academicAdminService.getAllSubjects();
        }
        return ResponseEntity.ok(ApiResponse.success("Subjects retrieved.", subjects));
    }

    @PutMapping("/subjects/{subjectId}")
    public ResponseEntity<ApiResponse<SubjectResponse>> updateSubject(
            @PathVariable Long subjectId,
            @Valid @RequestBody CreateSubjectRequest request
    ) {
        SubjectResponse response = academicAdminService.updateSubject(subjectId, request);
        return ResponseEntity.ok(ApiResponse.success("Subject updated successfully.", response));
    }

    @DeleteMapping("/subjects/{subjectId}")
    public ResponseEntity<ApiResponse<Void>> deleteSubject(@PathVariable Long subjectId) {
        academicAdminService.deleteSubject(subjectId);
        return ResponseEntity.ok(ApiResponse.success("Subject deleted successfully."));
    }
}
