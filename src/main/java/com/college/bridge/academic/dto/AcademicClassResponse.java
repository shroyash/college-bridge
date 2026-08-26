package com.college.bridge.academic.dto;

import com.college.bridge.academic.entity.AcademicClass;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class AcademicClassResponse {
    Long classId;
    String faculty;
    Integer semester;
    String displayName;
    Integer totalStudents;
    Long classTeacherId;
    String classTeacherName;

    public static AcademicClassResponse from(AcademicClass academicClass) {
        return from(academicClass, 0);
    }

    public static AcademicClassResponse from(AcademicClass academicClass, int totalStudents) {
        String teacherName = academicClass.getClassTeacher() != null && academicClass.getClassTeacher().getUser() != null
                ? academicClass.getClassTeacher().getUser().getFullName()
                : null;
        Long teacherId = academicClass.getClassTeacher() != null
                ? academicClass.getClassTeacher().getTeacherId()
                : null;

        return AcademicClassResponse.builder()
                .classId(academicClass.getClassId())
                .faculty(academicClass.getFaculty())
                .semester(academicClass.getSemester())
                .displayName(academicClass.getDisplayName())
                .totalStudents(totalStudents)
                .classTeacherId(teacherId)
                .classTeacherName(teacherName)
                .build();
    }
}
