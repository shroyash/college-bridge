package com.college.bridge.academic.dto;

import com.college.bridge.academic.entity.Subject;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class SubjectResponse {
    Long subjectId;
    String name;
    String faculty;
    Integer semester;
    Integer creditHours;

    public static SubjectResponse from(Subject subject) {
        return SubjectResponse.builder()
                .subjectId(subject.getSubjectId())
                .name(subject.getName())
                .faculty(subject.getFaculty())
                .semester(subject.getSemester())
                .creditHours(subject.getCreditHours())
                .build();
    }
}