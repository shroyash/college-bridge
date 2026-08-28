package com.college.bridge.auth.service;

import com.college.bridge.academic.entity.AcademicClass;
import com.college.bridge.academic.repository.AcademicClassRepository;
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
    private final AcademicClassRepository academicClassRepository;
    private final SubjectEnrollmentRepository subjectEnrollmentRepository;
    private final UserMapper userMapper;

    @Transactional(readOnly = true)
    public Page<UserProfileResponse> getStudentsFiltered(Principal principal, String faculty, Integer semester, String search, Pageable pageable) {
        Long tenantId = getTenantId(principal);
        String searchPattern = (search != null && !search.isBlank()) ? search.trim() : null;
        String facultyParam = (faculty != null && !faculty.isBlank()) ? faculty.trim() : null;

        return studentRepository.findStudentsFiltered(tenantId, facultyParam, semester, searchPattern, pageable)
                .map(student -> userMapper.toProfileResponse(student.getUser(), student));
    }

    @Transactional(readOnly = true)
    public StudentFilterOptionsResponse getStudentFilterOptions(Principal principal) {
        Long tenantId = getTenantId(principal);
        List<String> faculties = academicClassRepository.findDistinctFacultiesByInstitutionId(tenantId);
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

        AcademicClass targetClass = academicClassRepository
                .findByClassIdAndInstitution_InstitutionId(request.getTargetClassId(), tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Target Academic Class not found for ID: " + request.getTargetClassId()));

        long validStudents = studentRepository.countByStudentIdInAndTenantId(request.getStudentIds(), tenantId);
        if (validStudents != request.getStudentIds().size()) {
            throw new TenantMismatchException("One or more selected students do not belong to your institution.");
        }

        int updatedCount = studentRepository.bulkUpdateAcademicClass(request.getStudentIds(), targetClass.getClassId(), tenantId);

        subjectEnrollmentRepository.bulkDeleteByStudentIds(request.getStudentIds());

        subjectEnrollmentRepository.bulkInsertEnrollmentsForTargetClass(
                request.getStudentIds(),
                tenantId,
                targetClass.getFaculty(),
                targetClass.getSemester()
        );

        log.info("Bulk transferred {} students to AcademicClass {} (Faculty: {}, Sem: {}) for tenant {}.",
                updatedCount, targetClass.getClassId(), targetClass.getFaculty(), targetClass.getSemester(), tenantId);

        return BulkTransferResponse.builder()
                .success(true)
                .updatedStudents(updatedCount)
                .targetClass(BulkTransferResponse.TargetClassDto.builder()
                        .classId(targetClass.getClassId())
                        .faculty(targetClass.getFaculty())
                        .semester(targetClass.getSemester())
                        .displayName(targetClass.getDisplayName())
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
