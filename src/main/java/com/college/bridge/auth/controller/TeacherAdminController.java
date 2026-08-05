package com.college.bridge.auth.controller;


import com.college.bridge.auth.dto.CreateTeacherRequest;
import com.college.bridge.auth.dto.TeacherResponse;
import com.college.bridge.auth.dto.UpdateTeacherRequest;
import com.college.bridge.auth.service.TeacherService;
import com.college.bridge.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/teachers")
@RequiredArgsConstructor
public class TeacherAdminController {

    private final TeacherService teacherService;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<TeacherResponse> createTeacher(@Valid @RequestBody CreateTeacherRequest request) {
        TeacherResponse response = teacherService.createTeacher(request);
        return ApiResponse.success("Teacher created successfully.", response);
    }

    @GetMapping("/{teacherId}")
    public ApiResponse<TeacherResponse> getTeacher(@PathVariable Long teacherId) {
        TeacherResponse response = teacherService.getTeacher(teacherId);
        return ApiResponse.success("Teacher retrieved successfully.", response);
    }

    @GetMapping
    public ApiResponse<Page<TeacherResponse>> getTeachers(Pageable pageable) {
        Page<TeacherResponse> response = teacherService.getTeachers(pageable);
        return ApiResponse.success("Teachers retrieved successfully.", response);
    }

    @PutMapping("/{teacherId}")
    public ApiResponse<TeacherResponse> updateTeacher(@PathVariable Long teacherId, @Valid @RequestBody UpdateTeacherRequest request) {
        TeacherResponse response = teacherService.updateTeacher(teacherId, request);
        return ApiResponse.success("Teacher updated successfully.", response);
    }

    @DeleteMapping("/{teacherId}")
    public ApiResponse<Void> deleteTeacher(@PathVariable Long teacherId) {
        teacherService.deleteTeacher(teacherId);
        return ApiResponse.success("Teacher deleted successfully.");
    }
}