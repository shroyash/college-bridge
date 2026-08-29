package com.college.bridge.academic.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class TeacherAssignmentResponse {

    private Long assignmentId;

    private Long subjectId;

    private String subjectName;

    private String subjectCode;

    private Long levelId;

    private String levelName;

    private Long programId;

    private String programName;
}