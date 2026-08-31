package com.college.bridge.academic.controller;

import com.college.bridge.academic.dto.ClassDetailResponse;
import com.college.bridge.academic.service.StudentAcademicService;
import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/student/academic")
@RequiredArgsConstructor
public class StudentAcademicController {

    private final StudentAcademicService studentAcademicService;

    @GetMapping("/class-details")
    public ResponseEntity<ApiResponse<ClassDetailResponse>> getStudentClassDetails(
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        if (principal == null || principal.getStudentId() == null) {
            throw new AccessDeniedException("Only logged in students can access class details.");
        }
        ClassDetailResponse response = studentAcademicService.getStudentClassDetails(principal.getStudentId());
        return ResponseEntity.ok(ApiResponse.success("Student class details retrieved.", response));
    }
}
