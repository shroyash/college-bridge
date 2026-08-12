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
public class InstitutionRegistrationResponse {

    private Long institutionId;
    private String name;
    private String code;
    private InstitutionStatus status;
    private String message;
    private LocalDateTime submittedAt;
}
