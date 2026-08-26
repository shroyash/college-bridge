package com.college.bridge.academic.controller;

import com.college.bridge.academic.dto.AcademicClassResponse;
import com.college.bridge.academic.dto.ClassDetailResponse;
import com.college.bridge.academic.service.TeacherAcademicService;
import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/teacher/academic")
@PreAuthorize("hasRole('TEACHER')")
@RequiredArgsConstructor
public class TeacherAcademicController {

    private final TeacherAcademicService teacherAcademicService;

    @GetMapping("/my-classes")
    public ResponseEntity<ApiResponse<List<AcademicClassResponse>>> getMyClasses(
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        if (principal == null || principal.getTeacherId() == null) {
            throw new AccessDeniedException("Only logged in teachers can access their classes.");
        }
        List<AcademicClassResponse> classes = teacherAcademicService.getTeacherClasses(principal.getTeacherId());
        return ResponseEntity.ok(ApiResponse.success("Teacher classes retrieved.", classes));
    }

    @GetMapping("/classes/{classId}/details")
    public ResponseEntity<ApiResponse<ClassDetailResponse>> getClassDetails(
            @PathVariable Long classId,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        if (principal == null || principal.getTeacherId() == null) {
            throw new AccessDeniedException("Only logged in teachers can access class details.");
        }
        ClassDetailResponse response = teacherAcademicService.getTeacherClassDetails(principal.getTeacherId(), classId);
        return ResponseEntity.ok(ApiResponse.success("Teacher class details retrieved.", response));
    }
}
