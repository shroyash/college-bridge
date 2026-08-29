package com.college.bridge.academic.dto;

import com.college.bridge.academic.entity.AcademicLevel;
import com.college.bridge.academic.entity.AcademicLevelType;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class AcademicLevelResponse {
    Long levelId;
    Long programId;
    String programName;
    String programCode;
    String name;
    Integer levelNumber;
    AcademicLevelType type;
    String createdAt;

    public static AcademicLevelResponse from(AcademicLevel level) {
        return AcademicLevelResponse.builder()
                .levelId(level.getLevelId())
                .programId(level.getProgram().getProgramId())
                .programName(level.getProgram().getName())
                .programCode(level.getProgram().getCode())
                .name(level.getName())
                .levelNumber(level.getLevelNumber())
                .type(level.getType())
                .createdAt(level.getCreatedAt() != null ? level.getCreatedAt().toString() : null)
                .build();
    }
}
