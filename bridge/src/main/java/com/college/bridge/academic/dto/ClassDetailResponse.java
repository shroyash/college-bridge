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
public class ClassDetailResponse {
    private Long classId;
    private String displayName;
    private String faculty;
    private Integer semester;
    private Integer totalStudents;
    private Long classTeacherId;
    private String classTeacherName;
    private String institutionName;
    private Long institutionId;
    private String createdBy;
    private String createdAt;
    private String status;
    private List<ClassStudentResponse> students;
    private List<ClassTeacherResponse> teachers;
}
