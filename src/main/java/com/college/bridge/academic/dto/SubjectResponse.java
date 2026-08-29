package com.college.bridge.academic.dto;

import com.college.bridge.academic.entity.Subject;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class SubjectResponse {
    Long subjectId;
    Long levelId;
    String levelName;
    Long programId;
    String programName;
    String name;
    String code;
    Integer creditHours;
    String fcmTopicId;

    public static SubjectResponse from(Subject subject) {
        Long levelId = subject.getAcademicLevel() != null ? subject.getAcademicLevel().getLevelId() : null;
        String levelName = subject.getAcademicLevel() != null ? subject.getAcademicLevel().getName() : null;
        Long programId = (subject.getAcademicLevel() != null && subject.getAcademicLevel().getProgram() != null)
                ? subject.getAcademicLevel().getProgram().getProgramId() : null;
        String programName = (subject.getAcademicLevel() != null && subject.getAcademicLevel().getProgram() != null)
                ? subject.getAcademicLevel().getProgram().getName() : null;

        return SubjectResponse.builder()
                .subjectId(subject.getSubjectId())
                .levelId(levelId)
                .levelName(levelName)
                .programId(programId)
                .programName(programName)
                .name(subject.getName())
                .code(subject.getCode())
                .creditHours(subject.getCreditHours())
                .fcmTopicId(subject.getFcmTopicId())
                .build();
    }
}