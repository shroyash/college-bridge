package com.college.bridge.academic.controller;

import com.college.bridge.academic.dto.*;
import com.college.bridge.academic.service.AcademicAdminService;
import com.college.bridge.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/academic")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class AcademicAdminController {

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

    // --- STUDENT LEVEL MAPPING ---

    @PostMapping("/levels/{levelId}/students/{studentId}")
    public ResponseEntity<ApiResponse<ClassStudentResponse>> addStudentToLevel(
            @PathVariable Long levelId,
            @PathVariable Long studentId
    ) {
        ClassStudentResponse response = academicAdminService.addStudentToLevel(levelId, studentId);
        return ResponseEntity.ok(ApiResponse.success("Student assigned to academic level successfully.", response));
    }

    @DeleteMapping("/levels/{levelId}/students/{studentId}")
    public ResponseEntity<ApiResponse<Void>> removeStudentFromLevel(
            @PathVariable Long levelId,
            @PathVariable Long studentId
    ) {
        academicAdminService.removeStudentFromLevel(levelId, studentId);
        return ResponseEntity.ok(ApiResponse.success("Student removed from academic level."));
    }

    @GetMapping("/unassigned-students")
    public ResponseEntity<ApiResponse<List<ClassStudentResponse>>> getUnassignedStudents() {
        List<ClassStudentResponse> unassigned = academicAdminService.getUnassignedStudents();
        return ResponseEntity.ok(ApiResponse.success("Unassigned students retrieved.", unassigned));
    }
}
