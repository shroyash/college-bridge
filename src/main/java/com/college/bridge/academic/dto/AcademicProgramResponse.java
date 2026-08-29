package com.college.bridge.academic.dto;

import com.college.bridge.academic.entity.AcademicProgram;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class AcademicProgramResponse {
    Long programId;
    Long institutionId;
    String name;
    String code;
    String createdAt;

    public static AcademicProgramResponse from(AcademicProgram program) {
        return AcademicProgramResponse.builder()
                .programId(program.getProgramId())
                .institutionId(program.getInstitution().getInstitutionId())
                .name(program.getName())
                .code(program.getCode())
                .createdAt(program.getCreatedAt() != null ? program.getCreatedAt().toString() : null)
                .build();
    }
}
