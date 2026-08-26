package com.college.bridge.academic.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClassTeacherResponse {
    private Long teacherId;
    private Long userId;
    private String fullName;
    private String email;
    private List<String> assignedSubjects;
    private boolean isClassTeacher;
}
