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
public class InstitutionDocumentResponse {
    private Long documentId;
    private String documentUrl;
    private String documentType;
    private LocalDateTime uploadedAt;
}
