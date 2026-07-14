package com.college.bridge.auth.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/test")
public class TestSecuredController {

    private ResponseEntity<Map<String, String>> buildResponse(String message) {
        Map<String, String> response = new HashMap<>();
        response.put("status", "success");
        response.put("message", message);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/authenticated")
    public ResponseEntity<Map<String, String>> authenticated() {
        return buildResponse("Access granted: You are authenticated!");
    }

    @GetMapping("/student")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<Map<String, String>> studentOnly() {
        return buildResponse("Access granted: Student role confirmed!");
    }

    @GetMapping("/teacher")
    @PreAuthorize("hasRole('TEACHER')")
    public ResponseEntity<Map<String, String>> teacherOnly() {
        return buildResponse("Access granted: Teacher role confirmed!");
    }

    @GetMapping("/admin")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, String>> adminOnly() {
        return buildResponse("Access granted: Admin role confirmed!");
    }

    @GetMapping("/admin-or-teacher")
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<Map<String, String>> adminOrTeacher() {
        return buildResponse("Access granted: Admin or Teacher role confirmed!");
    }

    @GetMapping("/student-or-teacher")
    @PreAuthorize("hasAnyRole('STUDENT', 'TEACHER')")
    public ResponseEntity<Map<String, String>> studentOrTeacher() {
        return buildResponse("Access granted: Student or Teacher role confirmed!");
    }
}
