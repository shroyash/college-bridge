package com.college.bridge.academic.controller;

import com.college.bridge.academic.dto.AssignTeacherSubjectsRequest;
import com.college.bridge.academic.dto.TeacherAssignmentResponse;
import com.college.bridge.academic.service.TeacherAssignmentService;
import com.college.bridge.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;


@RestController
@RequestMapping("/api/admin/teachers/{teacherId}/subject-assignments")
@RequiredArgsConstructor
public class TeacherAssignmentAdminController {

    private final TeacherAssignmentService teacherAssignmentService;


    @PostMapping
    public ResponseEntity<ApiResponse<List<TeacherAssignmentResponse>>> assignSubjects(
            @PathVariable Long teacherId,
            @Valid @RequestBody AssignTeacherSubjectsRequest request) {

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(
                        "Subjects assigned successfully.",
                        teacherAssignmentService.assignSubjects(teacherId, request)
                ));
    }


    @GetMapping
    public ResponseEntity<ApiResponse<List<TeacherAssignmentResponse>>> getAssignments(
            @PathVariable Long teacherId) {

        return ResponseEntity.ok(
                ApiResponse.success(
                        "Teacher assignments retrieved successfully.",
                        teacherAssignmentService.getAssignments(teacherId)
                ));
    }


    @PutMapping
    public ResponseEntity<ApiResponse<List<TeacherAssignmentResponse>>> replaceAssignments(
            @PathVariable Long teacherId,
            @Valid @RequestBody AssignTeacherSubjectsRequest request) {

        return ResponseEntity.ok(
                ApiResponse.success(
                        "Teacher assignments updated successfully.",
                        teacherAssignmentService.replaceAssignments(teacherId, request)
                ));
    }


    @DeleteMapping("/{assignmentId}")
    public ResponseEntity<ApiResponse<Void>> deleteAssignment(
            @PathVariable Long assignmentId) {

        teacherAssignmentService.deleteAssignment(assignmentId);

        return ResponseEntity.ok(
                ApiResponse.success("Teacher assignment deleted successfully.")
        );
    }
}