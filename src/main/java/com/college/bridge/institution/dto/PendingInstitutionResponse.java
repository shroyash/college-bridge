package com.college.bridge.institution.dto;

import com.college.bridge.institution.entity.InstitutionStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PendingInstitutionResponse {

    private Long institutionId;
    private String name;
    private String code;
    private InstitutionStatus status;
    private Long submittedByUserId;
    private String submittedByAdminName;
    private String submittedByAdminEmail;
    private LocalDateTime createdAt;
    private List<InstitutionDocumentResponse> documents;
}
