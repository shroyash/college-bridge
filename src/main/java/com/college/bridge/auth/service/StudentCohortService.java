package com.college.bridge.auth.service;

import com.college.bridge.academic.entity.AcademicLevel;
import com.college.bridge.academic.repository.AcademicLevelRepository;
import com.college.bridge.academic.repository.AcademicProgramRepository;
import com.college.bridge.academic.repository.SubjectEnrollmentRepository;
import com.college.bridge.auth.dto.BulkTransferRequest;
import com.college.bridge.auth.dto.BulkTransferResponse;
import com.college.bridge.auth.dto.StudentFilterOptionsResponse;
import com.college.bridge.auth.dto.UserProfileResponse;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.mapper.UserMapper;
import com.college.bridge.auth.repository.StudentRepository;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.common.exception.BusinessRuleException;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.common.exception.TenantMismatchException;
import com.college.bridge.common.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.Principal;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class StudentCohortService {

    private final StudentRepository studentRepository;
    private final UserRepository userRepository;
    private final AcademicLevelRepository academicLevelRepository;
    private final AcademicProgramRepository academicProgramRepository;
    private final SubjectEnrollmentRepository subjectEnrollmentRepository;
    private final UserMapper userMapper;

    @Transactional(readOnly = true)
    public Page<UserProfileResponse> getStudentsFiltered(Principal principal, Long programId, Long levelId, String search, Pageable pageable) {
        Long tenantId = getTenantId(principal);
        String searchPattern = (search != null && !search.isBlank()) ? search.trim() : null;

        return studentRepository.findStudentsFiltered(tenantId, programId, levelId, searchPattern, pageable)
                .map(student -> userMapper.toProfileResponse(student.getUser(), student));
    }

    @Transactional(readOnly = true)
    public StudentFilterOptionsResponse getStudentFilterOptions(Principal principal) {
        Long tenantId = getTenantId(principal);
        List<String> faculties = academicProgramRepository.findByInstitution_InstitutionId(tenantId)
                .stream()
                .map(p -> p.getCode())
                .toList();

        List<Integer> semesters = List.of(1, 2, 3, 4, 5, 6, 7, 8);

        return StudentFilterOptionsResponse.builder()
                .faculties(faculties)
                .semesters(semesters)
                .build();
    }

    @Transactional
    public BulkTransferResponse bulkTransferStudents(Principal principal, BulkTransferRequest request) {
        Long tenantId = getTenantId(principal);

        if (request.getStudentIds() == null || request.getStudentIds().isEmpty()) {
            throw new BusinessRuleException("Student IDs list must not be empty.");
        }

        AcademicLevel targetLevel = academicLevelRepository
                .findByLevelIdAndProgram_Institution_InstitutionId(request.getTargetLevelId(), tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Target Academic Level not found for ID: " + request.getTargetLevelId()));

        long validStudents = studentRepository.countByStudentIdInAndTenantId(request.getStudentIds(), tenantId);
        if (validStudents != request.getStudentIds().size()) {
            throw new TenantMismatchException("One or more selected students do not belong to your institution.");
        }

        int updatedCount = studentRepository.bulkUpdateAcademicLevel(request.getStudentIds(), targetLevel.getLevelId(), tenantId);

        subjectEnrollmentRepository.bulkDeleteByStudentIds(request.getStudentIds());

        subjectEnrollmentRepository.bulkInsertEnrollmentsForTargetLevel(
                request.getStudentIds(),
                targetLevel.getLevelId()
        );

        log.info("Bulk transferred {} students to AcademicLevel {} (Name: {}) for tenant {}.",
                updatedCount, targetLevel.getLevelId(), targetLevel.getName(), tenantId);

        return BulkTransferResponse.builder()
                .success(true)
                .updatedStudents(updatedCount)
                .targetLevel(BulkTransferResponse.TargetLevelDto.builder()
                        .levelId(targetLevel.getLevelId())
                        .name(targetLevel.getName())
                        .levelNumber(targetLevel.getLevelNumber())
                        .type(targetLevel.getType())
                        .programId(targetLevel.getProgram().getProgramId())
                        .programName(targetLevel.getProgram().getName())
                        .build())
                .build();
    }

    private Long getTenantId(Principal principal) {
        Long tenantId = TenantContext.get();
        if (tenantId != null) {
            return tenantId;
        }
        if (principal != null && principal.getName() != null) {
            User user = userRepository.findByEmail(principal.getName()).orElse(null);
            if (user != null && user.getInstitution() != null) {
                return user.getInstitution().getInstitutionId();
            }
        }
        throw new BusinessRuleException("Institution context is missing.");
    }
}
