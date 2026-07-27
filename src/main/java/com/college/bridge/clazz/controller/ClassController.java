package com.college.bridge.clazz.controller;

import com.college.bridge.auth.security.CustomUserDetails;
import com.college.bridge.clazz.dto.AssignTeacherRequest;
import com.college.bridge.clazz.dto.ClassResponse;
import com.college.bridge.clazz.dto.CreateClassRequest;
import com.college.bridge.clazz.service.ClassService;
import com.college.bridge.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class ClassController {

    private final ClassService classService;

    @PostMapping("/api/admin/classes")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<ClassResponse>> createClass(
            @Valid @RequestBody CreateClassRequest request
    ) {
        ClassResponse response = classService.createClass(request);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("Class created successfully.", response));
    }

    @PostMapping("/api/admin/classes/{classId}/assign-teacher")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<ClassResponse>> assignTeacher(
            @PathVariable Long classId,
            @Valid @RequestBody AssignTeacherRequest request
    ) {
        ClassResponse response = classService.assignTeacher(classId, request);
        return ResponseEntity.ok(ApiResponse.success("Teacher assigned to class successfully.", response));
    }

    @GetMapping("/api/admin/classes")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<List<ClassResponse>>> getAllClasses() {
        List<ClassResponse> classes = classService.getAllClasses();
        return ResponseEntity.ok(ApiResponse.success("All classes retrieved.", classes));
    }

    @GetMapping("/api/classes/my-classes")
    public ResponseEntity<ApiResponse<List<ClassResponse>>> getMyClasses(
            @AuthenticationPrincipal CustomUserDetails userDetails
    ) {
        List<ClassResponse> classes = classService.getClassesForUser(
                userDetails.getUser().getUserId(),
                userDetails.getUser().getRole()
        );
        return ResponseEntity.ok(ApiResponse.success("User classes retrieved.", classes));
    }
}
