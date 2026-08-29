package com.college.bridge.academic.dto;

import com.college.bridge.academic.entity.AcademicLevelType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SubjectDetailResponse {

    private Long subjectId;
    private String subjectName;
    private String code;
    private Integer creditHours;
    private AcademicLevelInfoDto academicLevel;
    private AcademicProgramInfoDto academicProgram;
    private TeacherInfoDto teacher;
    private int studentCount;
    private List<ClassStudentResponse> students;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AcademicLevelInfoDto {
        private Long levelId;
        private String name;
        private Integer levelNumber;
        private AcademicLevelType type;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AcademicProgramInfoDto {
        private Long programId;
        private String name;
        private String code;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TeacherInfoDto {
        private Long teacherId;
        private Long userId;
        private String name;
        private String email;
    }
}
