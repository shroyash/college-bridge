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

    public static AcademicClassResponse from(AcademicClass academicClass) {
        return AcademicClassResponse.builder()
                .classId(academicClass.getClassId())
                .faculty(academicClass.getFaculty())
                .semester(academicClass.getSemester())
                .displayName(academicClass.getDisplayName())
                .build();
    }
}
