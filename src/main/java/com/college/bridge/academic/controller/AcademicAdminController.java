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

    @GetMapping("/faculties")
    public ResponseEntity<ApiResponse<List<String>>> getInstitutionFaculties() {
        List<String> faculties = academicAdminService.getInstitutionFaculties();
        return ResponseEntity.ok(ApiResponse.success("Institution faculties retrieved.", faculties));
    }

    @PostMapping("/classes")
    public ResponseEntity<ApiResponse<AcademicClassResponse>> createAcademicClass(
            @Valid @RequestBody CreateAcademicClassRequest request
    ) {
        AcademicClassResponse response = academicAdminService.createAcademicClass(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Academic class created successfully.", response));
    }

    @GetMapping("/classes")
    public ResponseEntity<ApiResponse<List<AcademicClassResponse>>> getAcademicClasses() {
        List<AcademicClassResponse> classes = academicAdminService.getAcademicClasses();
        return ResponseEntity.ok(ApiResponse.success("Academic classes retrieved.", classes));
    }

    @PutMapping("/classes/{classId}")
    public ResponseEntity<ApiResponse<AcademicClassResponse>> updateAcademicClass(
            @PathVariable Long classId,
            @Valid @RequestBody CreateAcademicClassRequest request
    ) {
        AcademicClassResponse response = academicAdminService.updateAcademicClass(classId, request);
        return ResponseEntity.ok(ApiResponse.success("Academic class updated successfully.", response));
    }

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
            @RequestParam(required = false) String faculty,
            @RequestParam(required = false) Integer semester
    ) {
        List<SubjectResponse> subjects = academicAdminService.getSubjects(faculty, semester);
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
