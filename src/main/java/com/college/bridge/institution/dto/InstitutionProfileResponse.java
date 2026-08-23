package com.college.bridge.institution.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InstitutionProfileResponse {

    private Long institutionId;
    private String name;
    private String code;
    private String status;
    private String location;
    private String website;
    private LocalDateTime createdAt;
    private long totalStudents;
    private long totalTeachers;
    private long totalClasses;
}
