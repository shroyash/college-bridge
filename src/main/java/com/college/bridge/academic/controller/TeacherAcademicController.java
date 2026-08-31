package com.college.bridge.academic.controller;

import com.college.bridge.academic.dto.AcademicLevelResponse;
import com.college.bridge.academic.dto.SubjectResponse;
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
@RequestMapping("/api/teacher/academic")
@PreAuthorize("hasRole('TEACHER')")
@RequiredArgsConstructor
public class TeacherAcademicController {

    private final TeacherAcademicService teacherAcademicService;

    @GetMapping("/my-subjects")
    public ResponseEntity<ApiResponse<List<SubjectResponse>>> getMySubjects(
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        if (principal == null || principal.getTeacherId() == null) {
            throw new AccessDeniedException("Only logged in teachers can access their subjects.");
        }
        List<SubjectResponse> subjects = teacherAcademicService.getTeacherAssignedSubjects(principal.getTeacherId());
        return ResponseEntity.ok(ApiResponse.success("Teacher assigned subjects retrieved.", subjects));
    }
}
