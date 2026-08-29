package com.college.bridge.auth.dto;

import com.college.bridge.academic.entity.AcademicLevelType;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BulkTransferResponse {
    private boolean success;
    private int updatedStudents;
    private TargetLevelDto targetLevel;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TargetLevelDto {
        private Long levelId;
        private String name;
        private Integer levelNumber;
        private AcademicLevelType type;
        private Long programId;
        private String programName;
    }
}
