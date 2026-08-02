package com.college.bridge.academic.controller;

import com.college.bridge.academic.dto.SubjectResponse;
import com.college.bridge.academic.entity.Faculty;
import com.college.bridge.academic.service.SubjectService;
import com.college.bridge.auth.security.CustomUserDetails;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/academic/subjects")
@RequiredArgsConstructor
public class SubjectController {

    private final SubjectService subjectService;


    @GetMapping
    public ResponseEntity<List<SubjectResponse>> getSubjectsByFacultyAndSemester(
            @RequestParam Faculty faculty,
            @RequestParam Integer semester) {
        return ResponseEntity.ok(subjectService.getSubjects(faculty, semester));
    }


    @GetMapping("/my-subjects")
    public ResponseEntity<List<SubjectResponse>> getMySubjects(
            @AuthenticationPrincipal CustomUserDetails principal) {

        Long studentId = principal.getStudentId();
        if (studentId == null) {
            throw new AccessDeniedException("Only students can access this resource");
        }
        return ResponseEntity.ok(subjectService.getSubjectsForStudent(studentId));
    }


    @PreAuthorize("hasRole('ADMIN') or hasRole('TEACHER')")
    @GetMapping("/student/{studentId}")
    public ResponseEntity<List<SubjectResponse>> getSubjectsForStudent(
            @PathVariable Long studentId) {
        return ResponseEntity.ok(subjectService.getSubjectsForStudent(studentId));
    }
}