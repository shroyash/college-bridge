package com.college.bridge.institution.service;

import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.entity.UserStatus;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.common.exception.BusinessRuleException;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.common.response.PageResponse;
import com.college.bridge.institution.dto.InstitutionDocumentResponse;
import com.college.bridge.institution.dto.SuperAdminInstitutionResponse;
import com.college.bridge.institution.dto.SuperAdminPendingInstitutionResponse;
import com.college.bridge.institution.entity.Institution;
import com.college.bridge.institution.entity.InstitutionStatus;
import com.college.bridge.institution.mapper.InstitutionMapper;
import com.college.bridge.institution.repository.InstitutionDocumentRepository;
import com.college.bridge.institution.repository.InstitutionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class SuperAdminInstitutionService {

    private final InstitutionRepository institutionRepository;
    private final InstitutionDocumentRepository institutionDocumentRepository;
    private final UserRepository userRepository;
    private final InstitutionMapper institutionMapper;

    @Transactional(readOnly = true)
    public PageResponse<SuperAdminInstitutionResponse> getAllInstitutions(
            Pageable pageable,
            String search,
            InstitutionStatus status
    ) {

        Page<Institution> institutionPage = institutionRepository.searchAll(
                status,
                normalize(search),
                pageable
        );

        List<Long> institutionIds = extractInstitutionIds(institutionPage.getContent());

        Map<Long, Map<UserRole, Long>> roleCounts = fetchUserCountsMap(institutionIds);
        Map<Long, Map<UserStatus, Long>> statusCounts = fetchUserStatusCountsMap(institutionIds);

        Page<SuperAdminInstitutionResponse> responsePage = institutionPage.map(institution -> {
            Map<UserRole, Long> roles = roleCounts.getOrDefault(institution.getInstitutionId(), Map.of());
            Map<UserStatus, Long> statuses = statusCounts.getOrDefault(institution.getInstitutionId(), Map.of());
            return institutionMapper.toSuperAdminResponse(
                    institution,
                    roles.getOrDefault(UserRole.STUDENT, 0L),
                    roles.getOrDefault(UserRole.TEACHER, 0L),
                    roles.getOrDefault(UserRole.ADMIN, 0L),
                    statuses.getOrDefault(UserStatus.ACTIVE, 0L),
                    statuses.getOrDefault(UserStatus.SUSPENDED, 0L)
            );
        });

        return PageResponse.from(responsePage);
    }

    @Transactional(readOnly = true)
    public List<SuperAdminPendingInstitutionResponse> getPendingInstitutions(String search) {

        List<Institution> institutions = StringUtils.hasText(search)
                ? institutionRepository.findByStatusAndSearch(InstitutionStatus.PENDING, search.trim())
                : institutionRepository.findByStatus(InstitutionStatus.PENDING);

        List<Long> institutionIds = extractInstitutionIds(institutions);

        Map<Long, Map<UserRole, Long>> roleCounts = fetchUserCountsMap(institutionIds);
        Map<Long, List<InstitutionDocumentResponse>> documentsMap = fetchDocumentsMap(institutionIds);

        return institutions.stream()
                .map(institution -> {
                    Map<UserRole, Long> roles = roleCounts.getOrDefault(institution.getInstitutionId(), Map.of());
                    List<InstitutionDocumentResponse> documents = documentsMap.getOrDefault(institution.getInstitutionId(), List.of());
                    return institutionMapper.toPendingResponse(
                            institution,
                            roles.getOrDefault(UserRole.STUDENT, 0L),
                            roles.getOrDefault(UserRole.TEACHER, 0L),
                            documents
                    );
                })
                .toList();
    }

    @Transactional
    public void approveInstitution(
            Long institutionId,
            Long superAdminUserId
    ) {

        Institution institution = getInstitution(institutionId);
        validatePendingInstitution(institution);
        User reviewer = getUser(superAdminUserId);

        institution.setStatus(InstitutionStatus.ACTIVE);
        institution.setReviewedBy(reviewer);
        institution.setReviewedAt(LocalDateTime.now());

        institutionRepository.save(institution);
        activateSubmittingAdmin(institution);
    }

    @Transactional
    public void rejectInstitution(
            Long institutionId,
            String rejectionReason,
            Long superAdminUserId
    ) {

        if (!StringUtils.hasText(rejectionReason)) {
            throw new BusinessRuleException("Rejection reason is required.");
        }

        Institution institution = getInstitution(institutionId);
        validatePendingInstitution(institution);
        User reviewer = getUser(superAdminUserId);

        institution.setStatus(InstitutionStatus.REJECTED);
        institution.setRejectionReason(rejectionReason.trim());
        institution.setReviewedBy(reviewer);
        institution.setReviewedAt(LocalDateTime.now());

        institutionRepository.save(institution);
    }

    @Transactional
    public void suspendInstitution(Long institutionId) {

        Institution institution = getInstitution(institutionId);

        if (institution.getStatus() == InstitutionStatus.SUSPENDED) {
            throw new BusinessRuleException("Institution is already suspended.");
        }

        institution.setStatus(InstitutionStatus.SUSPENDED);
        institutionRepository.save(institution);
    }

    @Transactional
    public void reactivateInstitution(Long institutionId) {

        Institution institution = getInstitution(institutionId);

        if (institution.getStatus() == InstitutionStatus.ACTIVE) {
            throw new BusinessRuleException("Institution is already active.");
        }

        institution.setStatus(InstitutionStatus.ACTIVE);
        institutionRepository.save(institution);
    }

    private String normalize(String search) {
        return StringUtils.hasText(search) ? search.trim() : null;
    }

    private List<Long> extractInstitutionIds(List<Institution> institutions) {
        return institutions.stream()
                .map(Institution::getInstitutionId)
                .toList();
    }

    private Map<Long, Map<UserRole, Long>> fetchUserCountsMap(List<Long> institutionIds) {

        if (institutionIds.isEmpty()) {
            return Map.of();
        }

        List<Object[]> rows = userRepository.countUsersGroupByInstitutionAndRole(institutionIds);
        Map<Long, Map<UserRole, Long>> result = new HashMap<>();

        for (Object[] row : rows) {
            Long institutionId = (Long) row[0];
            UserRole role = (UserRole) row[1];
            Long count = (Long) row[2];

            result.computeIfAbsent(institutionId, ignored -> new HashMap<>()).put(role, count);
        }

        return result;
    }

    private Map<Long, Map<UserStatus, Long>> fetchUserStatusCountsMap(List<Long> institutionIds) {

        if (institutionIds.isEmpty()) {
            return Map.of();
        }

        List<Object[]> rows = userRepository.countUsersGroupByInstitutionAndStatus(institutionIds);
        Map<Long, Map<UserStatus, Long>> result = new HashMap<>();

        for (Object[] row : rows) {
            Long institutionId = (Long) row[0];
            UserStatus status = (UserStatus) row[1];
            Long count = (Long) row[2];

            result.computeIfAbsent(institutionId, ignored -> new HashMap<>()).put(status, count);
        }

        return result;
    }

    private Map<Long, List<InstitutionDocumentResponse>> fetchDocumentsMap(List<Long> institutionIds) {

        if (institutionIds.isEmpty()) {
            return Map.of();
        }

        return institutionDocumentRepository
                .findByInstitution_InstitutionIdIn(institutionIds)
                .stream()
                .collect(Collectors.groupingBy(
                        document -> document.getInstitution().getInstitutionId(),
                        Collectors.mapping(document ->
                                        InstitutionDocumentResponse.builder()
                                                .documentId(document.getDocumentId())
                                                .documentUrl(document.getDocumentUrl())
                                                .documentType(document.getDocumentType())
                                                .uploadedAt(document.getUploadedAt())
                                                .build(),
                                Collectors.toList()
                        )
                ));
    }

    private Institution getInstitution(Long institutionId) {
        return institutionRepository.findById(institutionId)
                .orElseThrow(() -> new ResourceNotFoundException("Institution not found with id: " + institutionId));
    }

    private User getUser(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));
    }

    private void validatePendingInstitution(Institution institution) {
        if (institution.getStatus() != InstitutionStatus.PENDING) {
            throw new BusinessRuleException(
                    "Only PENDING institutions can be processed. Current status: " + institution.getStatus()
            );
        }
    }

    private void activateSubmittingAdmin(Institution institution) {
        User submittingAdmin = institution.getSubmittedBy();

        if (submittingAdmin == null) {
            submittingAdmin = userRepository
                    .findByInstitution_InstitutionIdAndRole(institution.getInstitutionId(), UserRole.ADMIN)
                    .stream()
                    .findFirst()
                    .orElse(null);
        }

        if (submittingAdmin == null) {
            log.warn("Institution approved but no admin found. institutionId={}", institution.getInstitutionId());
            return;
        }

        submittingAdmin.setStatus(UserStatus.ACTIVE);
        userRepository.save(submittingAdmin);
    }
}