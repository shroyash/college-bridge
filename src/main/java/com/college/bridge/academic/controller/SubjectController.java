package com.college.bridge.academic.controller;

import com.college.bridge.academic.dto.SubjectDetailResponse;
import com.college.bridge.academic.dto.SubjectResponse;
import com.college.bridge.academic.service.SubjectService;
import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Subject endpoints for students, teachers, and admins.
 * <p>
 * Q3 FIX: All responses now use the standard {@code ApiResponse<>} wrapper, consistent
 * with every other Academic controller. Flutter clients must read the {@code data} field.
 */
@RestController
@RequestMapping("/api/academic/subjects")
@RequiredArgsConstructor
public class SubjectController {

    private final SubjectService subjectService;


    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<SubjectResponse>> getSubjectById(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                ApiResponse.success("Subject retrieved.", subjectService.getSubjectById(id))
        );
    }


    @GetMapping("/{id}/details")
    public ResponseEntity<ApiResponse<SubjectDetailResponse>> getSubjectDetails(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal principal) {

        return ResponseEntity.ok(
                ApiResponse.success("Subject details retrieved.",
                        subjectService.getSubjectDetails(id, principal))
        );
    }


    @GetMapping
    public ResponseEntity<ApiResponse<List<SubjectResponse>>> getSubjectsByLevel(
            @RequestParam Long levelId) {

        return ResponseEntity.ok(
                ApiResponse.success("Subjects retrieved.",
                        subjectService.getSubjectsByLevel(levelId))
        );
    }


    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    @GetMapping("/all")
    public ResponseEntity<ApiResponse<List<SubjectResponse>>> getAllSubjects() {

        return ResponseEntity.ok(
                ApiResponse.success("All subjects retrieved.",
                        subjectService.getAllSubjects())
        );
    }


    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<SubjectResponse>>> searchSubjects(
            @RequestParam String name) {

        return ResponseEntity.ok(
                ApiResponse.success("Search results retrieved.",
                        subjectService.searchSubjects(name))
        );
    }


    @PreAuthorize("hasAnyRole('STUDENT', 'TEACHER')")
    @GetMapping("/my-subjects")
    public ResponseEntity<ApiResponse<List<SubjectResponse>>> getMySubjects(
            @AuthenticationPrincipal UserPrincipal principal) {

        return ResponseEntity.ok(
                ApiResponse.success("My subjects retrieved.",
                        subjectService.getMySubjects(principal))
        );
    }


    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    @GetMapping("/student/{studentId}")
    public ResponseEntity<ApiResponse<List<SubjectResponse>>> getSubjectsForStudent(
            @PathVariable Long studentId) {

        return ResponseEntity.ok(
                ApiResponse.success("Student subjects retrieved.",
                        subjectService.getSubjectsForStudent(studentId))
        );
    }
}