package com.college.bridge.institution.dto;

import com.college.bridge.institution.entity.InstitutionStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SuperAdminPendingInstitutionResponse {

    private Long institutionId;
    private String institutionName;
    private String profileImage;
    private String location;
    private String website;
    private String contactPerson;
    private String email;
    private InstitutionStatus status;
    private long totalStudents;
    private long totalTeachers;
    private LocalDateTime submittedAt;
}
