package com.college.bridge.auth.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BulkTransferResponse {
    private boolean success;
    private int updatedStudents;
    private TargetClassDto targetClass;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TargetClassDto {
        private Long classId;
        private String faculty;
        private Integer semester;
        private String displayName;
    }
}
