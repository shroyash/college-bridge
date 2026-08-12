package com.college.bridge.institution.service;

import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.entity.UserStatus;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.common.exception.BusinessRuleException;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.institution.dto.InstitutionDocumentResponse;
import com.college.bridge.institution.dto.PendingInstitutionResponse;
import com.college.bridge.institution.entity.Institution;
import com.college.bridge.institution.entity.InstitutionStatus;
import com.college.bridge.institution.repository.InstitutionDocumentRepository;
import com.college.bridge.institution.repository.InstitutionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class SuperAdminInstitutionService {

    private final InstitutionRepository institutionRepository;
    private final InstitutionDocumentRepository institutionDocumentRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public List<PendingInstitutionResponse> getPendingInstitutions() {
        List<Institution> pendingInstitutions = institutionRepository.findByStatus(InstitutionStatus.PENDING);

        return pendingInstitutions.stream().map(inst -> {
            List<InstitutionDocumentResponse> docs = institutionDocumentRepository
                    .findByInstitution_InstitutionId(inst.getInstitutionId())
                    .stream()
                    .map(doc -> InstitutionDocumentResponse.builder()
                            .documentId(doc.getDocumentId())
                            .documentUrl(doc.getDocumentUrl())
                            .documentType(doc.getDocumentType())
                            .uploadedAt(doc.getUploadedAt())
                            .build())
                    .toList();

            User submittedBy = inst.getSubmittedBy();

            return PendingInstitutionResponse.builder()
                    .institutionId(inst.getInstitutionId())
                    .name(inst.getName())
                    .code(inst.getCode())
                    .status(inst.getStatus())
                    .submittedByUserId(submittedBy != null ? submittedBy.getUserId() : null)
                    .submittedByAdminName(submittedBy != null ? submittedBy.getName() : null)
                    .submittedByAdminEmail(submittedBy != null ? submittedBy.getEmail() : null)
                    .createdAt(inst.getCreatedAt())
                    .documents(docs)
                    .build();
        }).toList();
    }

    @Transactional
    public void approveInstitution(Long institutionId, Long superAdminUserId) {
        Institution institution = institutionRepository.findById(institutionId)
                .orElseThrow(() -> new ResourceNotFoundException("Institution not found with id: " + institutionId));

        if (institution.getStatus() != InstitutionStatus.PENDING) {
            throw new BusinessRuleException("Only PENDING institutions can be approved. Current status: " + institution.getStatus());
        }

        User reviewer = userRepository.findById(superAdminUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Super admin user not found with id: " + superAdminUserId));

        institution.setStatus(InstitutionStatus.ACTIVE);
        institution.setReviewedBy(reviewer);
        institution.setReviewedAt(LocalDateTime.now());
        institutionRepository.save(institution);

        // Find submitting admin user and flip status to ACTIVE
        User submittingAdmin = institution.getSubmittedBy();
        if (submittingAdmin == null) {
            // Fallback: search for ADMIN user in this institution
            submittingAdmin = userRepository.findByInstitution_InstitutionIdAndRole(institutionId, UserRole.ADMIN)
                    .stream().findFirst().orElse(null);
        }

        if (submittingAdmin != null) {
            submittingAdmin.setStatus(UserStatus.ACTIVE);
            userRepository.save(submittingAdmin);
            log.info("Approved institution '{}' (id={}) and activated admin user '{}' (userId={}).",
                    institution.getName(), institutionId, submittingAdmin.getEmail(), submittingAdmin.getUserId());
        } else {
            log.warn("Approved institution '{}' (id={}) but no submitting admin user was found to activate.",
                    institution.getName(), institutionId);
        }
    }

    @Transactional
    public void rejectInstitution(Long institutionId, String rejectionReason, Long superAdminUserId) {
        Institution institution = institutionRepository.findById(institutionId)
                .orElseThrow(() -> new ResourceNotFoundException("Institution not found with id: " + institutionId));

        if (institution.getStatus() != InstitutionStatus.PENDING) {
            throw new BusinessRuleException("Only PENDING institutions can be rejected. Current status: " + institution.getStatus());
        }

        User reviewer = userRepository.findById(superAdminUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Super admin user not found with id: " + superAdminUserId));

        institution.setStatus(InstitutionStatus.REJECTED);
        institution.setRejectionReason(rejectionReason);
        institution.setReviewedBy(reviewer);
        institution.setReviewedAt(LocalDateTime.now());
        institutionRepository.save(institution);

        log.info("Rejected institution '{}' (id={}). Reason: {}", institution.getName(), institutionId, rejectionReason);
    }

    @Transactional
    public void suspendInstitution(Long institutionId) {
        Institution institution = institutionRepository.findById(institutionId)
                .orElseThrow(() -> new ResourceNotFoundException("Institution not found with id: " + institutionId));

        institution.setStatus(InstitutionStatus.SUSPENDED);
        institutionRepository.save(institution);

        log.info("Suspended institution '{}' (id={}). Individual user status untouched.", institution.getName(), institutionId);
    }

    @Transactional
    public void reactivateInstitution(Long institutionId) {
        Institution institution = institutionRepository.findById(institutionId)
                .orElseThrow(() -> new ResourceNotFoundException("Institution not found with id: " + institutionId));

        institution.setStatus(InstitutionStatus.ACTIVE);
        institutionRepository.save(institution);

        log.info("Reactivated institution '{}' (id={}). Individual user status untouched.", institution.getName(), institutionId);
    }
}
