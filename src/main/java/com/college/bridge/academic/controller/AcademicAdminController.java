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
    public ResponseEntity<ApiResponse<List<AcademicClassResponse>>> getAcademicClasses(
            @RequestParam(required = false) String faculty,
            @RequestParam(required = false) Integer semester,
            @RequestParam(required = false) String search
    ) {
        List<AcademicClassResponse> classes = academicAdminService.getAcademicClassesFiltered(faculty, semester, search);
        return ResponseEntity.ok(ApiResponse.success("Academic classes retrieved.", classes));
    }

    @GetMapping("/classes/{classId}/details")
    public ResponseEntity<ApiResponse<ClassDetailResponse>> getClassDetails(@PathVariable Long classId) {
        ClassDetailResponse response = academicAdminService.getClassDetails(classId);
        return ResponseEntity.ok(ApiResponse.success("Class details retrieved successfully.", response));
    }

    @PostMapping("/classes/{classId}/students/{studentId}")
    public ResponseEntity<ApiResponse<ClassStudentResponse>> addStudentToClass(
            @PathVariable Long classId,
            @PathVariable Long studentId
    ) {
        ClassStudentResponse response = academicAdminService.addStudentToClass(classId, studentId);
        return ResponseEntity.ok(ApiResponse.success("Student added to class successfully.", response));
    }

    @DeleteMapping("/classes/{classId}/students/{studentId}")
    public ResponseEntity<ApiResponse<Void>> removeStudentFromClass(
            @PathVariable Long classId,
            @PathVariable Long studentId
    ) {
        academicAdminService.removeStudentFromClass(classId, studentId);
        return ResponseEntity.ok(ApiResponse.success("Student removed from class."));
    }

    @PutMapping("/classes/{classId}/class-teacher/{teacherId}")
    public ResponseEntity<ApiResponse<AcademicClassResponse>> assignClassTeacher(
            @PathVariable Long classId,
            @PathVariable Long teacherId
    ) {
        AcademicClassResponse response = academicAdminService.assignClassTeacher(classId, teacherId);
        return ResponseEntity.ok(ApiResponse.success("Class teacher assigned successfully.", response));
    }

    @GetMapping("/unassigned-students")
    public ResponseEntity<ApiResponse<List<ClassStudentResponse>>> getUnassignedStudents() {
        List<ClassStudentResponse> unassigned = academicAdminService.getUnassignedStudents();
        return ResponseEntity.ok(ApiResponse.success("Unassigned students retrieved.", unassigned));
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
