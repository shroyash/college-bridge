package com.college.bridge.academic.controller;

import com.college.bridge.academic.dto.SubjectResponse;
import com.college.bridge.academic.service.SubjectService;
import com.college.bridge.auth.security.UserPrincipal;
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

    @GetMapping("/{id}")
    public ResponseEntity<SubjectResponse> getSubjectById(@PathVariable("id") Long id) {
        return ResponseEntity.ok(subjectService.getSubjectById(id));
    }

    @GetMapping
    public ResponseEntity<List<SubjectResponse>> getSubjectsByFacultyAndSemester(
            @RequestParam String faculty,
            @RequestParam Integer semester) {
        return ResponseEntity.ok(subjectService.getSubjects(faculty, semester));
    }

    @GetMapping("/all")
    public ResponseEntity<List<SubjectResponse>> getAllSubjects() {
        return ResponseEntity.ok(subjectService.getAllSubjects());
    }

    @GetMapping("/search")
    public ResponseEntity<List<SubjectResponse>> searchSubjects(
            @RequestParam String name) {
        return ResponseEntity.ok(subjectService.searchSubjects(name));
    }

    @GetMapping("/my-subjects")
    public ResponseEntity<List<SubjectResponse>> getMySubjects(
            @AuthenticationPrincipal UserPrincipal principal) {

        Long studentId =principal.getStudentId();
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