package com.college.bridge.academic.service;

import com.college.bridge.academic.dto.ClassStudentResponse;
import com.college.bridge.academic.entity.AcademicLevel;
import com.college.bridge.academic.mapper.SubjectMapper;
import com.college.bridge.academic.repository.AcademicLevelRepository;
import com.college.bridge.academic.repository.AcademicProgramRepository;
import com.college.bridge.academic.repository.SubjectEnrollmentRepository;
import com.college.bridge.auth.dto.BulkTransferRequest;
import com.college.bridge.auth.dto.BulkTransferResponse;
import com.college.bridge.auth.dto.StudentFilterOptionsResponse;
import com.college.bridge.auth.dto.UserProfileResponse;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.mapper.UserMapper;
import com.college.bridge.auth.repository.StudentRepository;
import com.college.bridge.common.exception.BusinessRuleException;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.common.exception.TenantMismatchException;
import com.college.bridge.common.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.Principal;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class StudentCohortService {

    private final StudentRepository studentRepository;
    private final AcademicLevelRepository academicLevelRepository;
    private final AcademicProgramRepository academicProgramRepository;
    private final SubjectEnrollmentRepository subjectEnrollmentRepository;
    private final UserMapper userMapper;
    private final SubjectMapper subjectMapper;

    @Transactional(readOnly = true)
    public Page<UserProfileResponse> getStudentsFiltered(
            Principal principal, Long programId, Long levelId, String search, Pageable pageable) {
        Long tenantId = requireTenantId();
        String searchPattern = (search != null && !search.isBlank()) ? search.trim() : null;

        return studentRepository.findStudentsFiltered(tenantId, programId, levelId, searchPattern, pageable)
                .map(student -> userMapper.toProfileResponse(student.getUser(), student));
    }

    @Transactional(readOnly = true)
    public StudentFilterOptionsResponse getStudentFilterOptions(Principal principal) {
        Long tenantId = requireTenantId();
        List<String> faculties = academicProgramRepository
                .findByInstitution_InstitutionIdAndDeletedFalse(tenantId)
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
        Long tenantId = requireTenantId();

        if (request.getStudentIds() == null || request.getStudentIds().isEmpty()) {
            throw new BusinessRuleException("Student IDs list must not be empty.");
        }

        AcademicLevel targetLevel = academicLevelRepository
                .findActiveByIdAndInstitutionId(request.getTargetLevelId(), tenantId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Target Academic Level not found for ID: " + request.getTargetLevelId()));

        long validStudents = studentRepository.countByStudentIdInAndTenantId(request.getStudentIds(), tenantId);
        if (validStudents != request.getStudentIds().size()) {
            throw new TenantMismatchException("One or more selected students do not belong to your institution.");
        }

        int updatedCount = studentRepository.bulkUpdateAcademicLevel(
                request.getStudentIds(), targetLevel.getLevelId(), tenantId);

        subjectEnrollmentRepository.bulkDeleteByStudentIds(request.getStudentIds());

        subjectEnrollmentRepository.bulkInsertEnrollmentsForTargetLevel(
                request.getStudentIds(), targetLevel.getLevelId());

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

    @Transactional
    public ClassStudentResponse addStudentToLevel(Long levelId, Long studentId) {
        Long tenantId = requireTenantId();
        AcademicLevel level = academicLevelRepository
                .findActiveByIdAndInstitutionId(levelId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic level not found with ID: " + levelId));

        Student student = studentRepository.findByStudentIdAndUser_Institution_InstitutionId(studentId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Student not found or access denied: " + studentId));

        student.setAcademicLevel(level);
        Student saved = studentRepository.save(student);

        return subjectMapper.toClassStudentResponse(saved);
    }

    @Transactional
    public void removeStudentFromLevel(Long levelId, Long studentId) {
        Long tenantId = requireTenantId();
        academicLevelRepository
                .findActiveByIdAndInstitutionId(levelId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic level not found with ID: " + levelId));

        Student student = studentRepository.findByStudentIdAndUser_Institution_InstitutionId(studentId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Student not found or access denied: " + studentId));

        if (student.getAcademicLevel() != null && student.getAcademicLevel().getLevelId().equals(levelId)) {
            student.setAcademicLevel(null);
            studentRepository.save(student);
        }
    }

    @Transactional(readOnly = true)
    public List<ClassStudentResponse> getUnassignedStudents() {
        Long tenantId = requireTenantId();
        List<Student> students = studentRepository.findByUser_Institution_InstitutionIdAndAcademicLevelIsNull(tenantId);
        return subjectMapper.toClassStudentResponseList(students);
    }

    private Long requireTenantId() {
        Long tenantId = TenantContext.get();
        if (tenantId == null) {
            throw new TenantMismatchException("Institution context is missing. Ensure you are authenticated.");
        }
        return tenantId;
    }
}
