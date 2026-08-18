package com.college.bridge.institution.service;

import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.entity.UserStatus;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.common.exception.BusinessRuleException;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.common.response.PageResponse;
import com.college.bridge.institution.dto.*;
import com.college.bridge.institution.entity.Institution;
import com.college.bridge.institution.entity.InstitutionStatus;
import com.college.bridge.institution.repository.InstitutionDocumentRepository;
import com.college.bridge.institution.repository.InstitutionRepository;
import jakarta.persistence.criteria.Predicate;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class SuperAdminInstitutionService {

    private final InstitutionRepository institutionRepository;
    private final InstitutionDocumentRepository institutionDocumentRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public PageResponse<SuperAdminInstitutionResponse> getAllInstitutions(
            Pageable pageable,
            String search,
            InstitutionStatus status
    ) {
        Specification<Institution> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (search != null && !search.trim().isEmpty()) {
                String searchPattern = "%" + search.trim().toLowerCase() + "%";
                Predicate nameLike = cb.like(cb.lower(root.get("name")), searchPattern);
                Predicate codeLike = cb.like(cb.lower(root.get("code")), searchPattern);
                predicates.add(cb.or(nameLike, codeLike));
            }

            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<Institution> page = institutionRepository.findAll(spec, pageable);
        Map<Long, Map<UserRole, Long>> countsMap = fetchUserCountsMap();

        Page<SuperAdminInstitutionResponse> dtoPage = page.map(inst -> {
            Map<UserRole, Long> roleCounts = countsMap.getOrDefault(inst.getInstitutionId(), Map.of());
            long students = roleCounts.getOrDefault(UserRole.STUDENT, 0L);
            long teachers = roleCounts.getOrDefault(UserRole.TEACHER, 0L);

            return SuperAdminInstitutionResponse.builder()
                    .institutionId(inst.getInstitutionId())
                    .institutionName(inst.getName())
                    .profileImage(inst.getProfileImage())
                    .location(inst.getLocation() != null ? inst.getLocation() : "Kathmandu")
                    .website(inst.getWebsite())
                    .status(inst.getStatus())
                    .totalStudents(students)
                    .totalTeachers(teachers)
                    .createdAt(inst.getCreatedAt())
                    .build();
        });

        return PageResponse.from(dtoPage);
    }

    @Transactional(readOnly = true)
    public PageResponse<SuperAdminPendingInstitutionResponse> getPendingInstitutionsPaginated(
            Pageable pageable,
            String search
    ) {
        Specification<Institution> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(root.get("status"), InstitutionStatus.PENDING));

            if (search != null && !search.trim().isEmpty()) {
                String searchPattern = "%" + search.trim().toLowerCase() + "%";
                Predicate nameLike = cb.like(cb.lower(root.get("name")), searchPattern);
                Predicate codeLike = cb.like(cb.lower(root.get("code")), searchPattern);
                predicates.add(cb.or(nameLike, codeLike));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<Institution> page = institutionRepository.findAll(spec, pageable);
        Map<Long, Map<UserRole, Long>> countsMap = fetchUserCountsMap();

        Page<SuperAdminPendingInstitutionResponse> dtoPage = page.map(inst -> {
            Map<UserRole, Long> roleCounts = countsMap.getOrDefault(inst.getInstitutionId(), Map.of());
            long students = roleCounts.getOrDefault(UserRole.STUDENT, 0L);
            long teachers = roleCounts.getOrDefault(UserRole.TEACHER, 0L);

            User submittedBy = inst.getSubmittedBy();
            String contactPerson = submittedBy != null ? submittedBy.getName() : null;
            String email = submittedBy != null ? submittedBy.getEmail() : null;

            return SuperAdminPendingInstitutionResponse.builder()
                    .institutionId(inst.getInstitutionId())
                    .institutionName(inst.getName())
                    .profileImage(inst.getProfileImage())
                    .location(inst.getLocation() != null ? inst.getLocation() : "Kathmandu")
                    .website(inst.getWebsite())
                    .contactPerson(contactPerson)
                    .email(email)
                    .status(inst.getStatus())
                    .totalStudents(students)
                    .totalTeachers(teachers)
                    .submittedAt(inst.getCreatedAt())
                    .build();
        });

        return PageResponse.from(dtoPage);
    }

    private Map<Long, Map<UserRole, Long>> fetchUserCountsMap() {
        List<Object[]> rawCounts = userRepository.countUsersGroupByInstitutionAndRole();
        Map<Long, Map<UserRole, Long>> countsMap = new HashMap<>();

        for (Object[] row : rawCounts) {
            Long instId = (Long) row[0];
            UserRole role = (UserRole) row[1];
            Long count = (Long) row[2];

            countsMap.computeIfAbsent(instId, k -> new HashMap<>()).put(role, count);
        }

        return countsMap;
    }

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

        User submittingAdmin = institution.getSubmittedBy();
        if (submittingAdmin == null) {
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
