package com.college.bridge.academic.controller;

import com.college.bridge.academic.dto.ClassStudentResponse;
import com.college.bridge.auth.dto.BulkTransferRequest;
import com.college.bridge.auth.dto.BulkTransferResponse;
import com.college.bridge.auth.dto.StudentFilterOptionsResponse;
import com.college.bridge.auth.dto.UserProfileResponse;
import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.academic.service.StudentCohortService;
import com.college.bridge.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/admin/students")
@RequiredArgsConstructor
public class StudentCohortController {

    private final StudentCohortService studentCohortService;

    @GetMapping
    public ResponseEntity<ApiResponse<Page<UserProfileResponse>>> getStudents(
            @RequestParam(required = false) Long programId,
            @RequestParam(required = false) Long levelId,
            @RequestParam(required = false) String faculty,
            @RequestParam(required = false) Integer semester,
            @RequestParam(required = false) String search,
            Pageable pageable,
            Principal principal
    ) {
        Page<UserProfileResponse> page = studentCohortService.getStudentsFiltered(
                principal, programId, levelId, faculty, semester, search, pageable);
        return ResponseEntity.ok(ApiResponse.success("Students fetched successfully.", page));
    }

    @GetMapping("/filter-options")
    public ResponseEntity<ApiResponse<StudentFilterOptionsResponse>> getStudentFilterOptions(
            Principal principal
    ) {
        StudentFilterOptionsResponse options = studentCohortService.getStudentFilterOptions(principal);
        return ResponseEntity.ok(ApiResponse.success("Student filter options fetched.", options));
    }

    @PostMapping("/bulk-transfer")
    public ResponseEntity<ApiResponse<BulkTransferResponse>> bulkTransferStudents(
            @Valid @RequestBody BulkTransferRequest request,
            Principal principal
    ) {
        BulkTransferResponse response = studentCohortService.bulkTransferStudents(principal, request);
        return ResponseEntity.ok(
                ApiResponse.success(response.getUpdatedStudents() + " students successfully updated.", response)
        );
    }

    @PostMapping("/levels/{levelId}/students/{studentId}")
    public ResponseEntity<ApiResponse<ClassStudentResponse>> addStudentToLevel(
            @PathVariable Long levelId,
            @PathVariable Long studentId
    ) {
        ClassStudentResponse response = studentCohortService.addStudentToLevel(levelId, studentId);
        return ResponseEntity.ok(ApiResponse.success("Student assigned to academic level successfully.", response));
    }

    @DeleteMapping("/levels/{levelId}/students/{studentId}")
    public ResponseEntity<ApiResponse<Void>> removeStudentFromLevel(
            @PathVariable Long levelId,
            @PathVariable Long studentId
    ) {
        studentCohortService.removeStudentFromLevel(levelId, studentId);
        return ResponseEntity.ok(ApiResponse.success("Student removed from academic level."));
    }

    @GetMapping("/unassigned-students")
    public ResponseEntity<ApiResponse<List<ClassStudentResponse>>> getUnassignedStudents() {
        List<ClassStudentResponse> unassigned = studentCohortService.getUnassignedStudents();
        return ResponseEntity.ok(ApiResponse.success("Unassigned students retrieved.", unassigned));
    }
}