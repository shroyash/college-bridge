package com.college.bridge.academic.service;

import com.college.bridge.academic.dto.ClassStudentResponse;
import com.college.bridge.academic.dto.SubjectDetailResponse;
import com.college.bridge.academic.dto.SubjectResponse;
import com.college.bridge.academic.entity.ClassStatus;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.entity.SubjectEnrollment;
import com.college.bridge.academic.entity.TeacherAssignment;
import com.college.bridge.academic.mapper.SubjectMapper;
import com.college.bridge.academic.repository.SubjectEnrollmentRepository;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.academic.repository.TeacherAssignmentRepository;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.repository.StudentRepository;
import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.common.exception.TenantMismatchException;
import com.college.bridge.common.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class SubjectService {

    private final SubjectRepository subjectRepository;
    private final SubjectEnrollmentRepository subjectEnrollmentRepository;
    private final TeacherAssignmentRepository teacherAssignmentRepository;
    private final SubjectMapper subjectMapper;
    private final StudentRepository studentRepository;


    @Transactional(readOnly = true)
    public SubjectResponse getSubjectById(Long subjectId) {
        Long tenantId = requireTenant();

        Subject subject = subjectRepository
                .findActiveByIdAndInstitutionId(subjectId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Subject", subjectId));

        return subjectMapper.toResponse(subject);
    }


    @Transactional(readOnly = true)
    public List<SubjectResponse> getSubjectsByLevel(Long levelId) {
        Long tenantId = requireTenant();

        return subjectRepository
                .findActiveByLevelIdAndInstitutionId(levelId, tenantId)
                .stream()
                .map(subjectMapper::toResponse)
                .toList();
    }


    @Transactional(readOnly = true)
    public List<SubjectResponse> getAllSubjects() {
        Long tenantId = requireTenant();

        return subjectRepository
                .findActiveByInstitutionId(tenantId)
                .stream()
                .map(subjectMapper::toResponse)
                .toList();
    }


    @Transactional(readOnly = true)
    public List<SubjectResponse> searchSubjects(String name) {
        Long tenantId = requireTenant();

        if (name == null || name.isBlank()) {
            return List.of();
        }

        return subjectRepository
                .findActiveByInstitutionIdAndNameContaining(tenantId, name.trim())
                .stream()
                .map(subjectMapper::toResponse)
                .toList();
    }


    @Transactional(readOnly = true)
    public List<SubjectResponse> getMySubjects(UserPrincipal principal) {
        if (principal == null) {
            throw new AccessDeniedException("Authentication required");
        }

        if (principal.getTeacherId() != null) {
            Long tenantId = requireTenant();
            return teacherAssignmentRepository
                    .findActiveByTeacherIdAndInstitutionId(principal.getTeacherId(), tenantId)
                    .stream()
                    .map(ta -> {
                        String tName = (ta.getTeacher() != null && ta.getTeacher().getUser() != null)
                                ? ta.getTeacher().getUser().getFullName()
                                : null;
                        return subjectMapper.toResponse(ta.getSubject(), tName);
                    })
                    .toList();
        }

        if (principal.getStudentId() != null) {
            return getSubjectsForStudent(principal.getStudentId());
        }

        throw new AccessDeniedException("Only logged in students or teachers can access their subjects.");
    }

    @Transactional(readOnly = true)
    public List<SubjectResponse> getSubjectsForStudent(Long studentId) {

        Long tenantId = requireTenant();

        if (studentId == null) {
            throw new AccessDeniedException("Student information not available");
        }

        boolean studentExists = studentRepository
                .existsByStudentIdAndUser_Institution_InstitutionId(
                        studentId,
                        tenantId
                );

        if (!studentExists) {
            throw new ResourceNotFoundException("Student not found");
        }

        return subjectEnrollmentRepository
                .findSubjectsForStudent(studentId, tenantId);
    }


    @Transactional(readOnly = true)
    public SubjectDetailResponse getSubjectDetails(Long subjectId, UserPrincipal principal) {
        Long tenantId = requireTenant();

        if (principal == null) {
            throw new AccessDeniedException("Authentication required");
        }

        Subject subject = subjectRepository
                .findSubjectDetails(subjectId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Subject", subjectId));

        validateSubjectAccess(subjectId, tenantId, principal);

        List<ClassStudentResponse> students = subjectEnrollmentRepository
                .findBySubject_SubjectId(subjectId)
                .stream()
                .map(subjectMapper::toClassStudentResponse)
                .toList();

        TeacherAssignment assignment = teacherAssignmentRepository
                .findFirstBySubject_SubjectId(subjectId)
                .orElse(null);

        var teacher = assignment != null ? assignment.getTeacher() : null;

        return subjectMapper.toDetailResponse(subject, teacher, students);
    }

    @Transactional
    public SubjectDetailResponse suspendSubject(Long subjectId, UserPrincipal principal) {
        Long tenantId = requireTenant();
        Subject subject = subjectRepository.findActiveByIdAndInstitutionId(subjectId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Subject", subjectId));

        if (subject.getAcademicLevel() != null) {
            subject.getAcademicLevel().setStatus(ClassStatus.SUSPENDED);
        }
        subjectRepository.save(subject);

        return getSubjectDetails(subjectId, principal);
    }

    @Transactional
    public SubjectDetailResponse activateSubject(Long subjectId, UserPrincipal principal) {
        Long tenantId = requireTenant();
        Subject subject = subjectRepository.findActiveByIdAndInstitutionId(subjectId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Subject", subjectId));

        if (subject.getAcademicLevel() != null) {
            subject.getAcademicLevel().setStatus(ClassStatus.ACTIVE);
        }
        subjectRepository.save(subject);

        return getSubjectDetails(subjectId, principal);
    }

    @Transactional
    public SubjectDetailResponse suspendStudentInSubject(Long subjectId, Long studentId, UserPrincipal principal) {
        Long tenantId = requireTenant();
        subjectRepository.findActiveByIdAndInstitutionId(subjectId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Subject", subjectId));

        validateTeacherOrAdminPermission(subjectId, tenantId, principal);

        SubjectEnrollment enrollment = subjectEnrollmentRepository
                .findBySubject_SubjectIdAndStudent_StudentId(subjectId, studentId)
                .orElseThrow(() -> new ResourceNotFoundException("Student is not enrolled in this subject."));

        enrollment.setStatus(ClassStatus.SUSPENDED);
        subjectEnrollmentRepository.save(enrollment);

        return getSubjectDetails(subjectId, principal);
    }

    @Transactional
    public SubjectDetailResponse activateStudentInSubject(Long subjectId, Long studentId, UserPrincipal principal) {
        Long tenantId = requireTenant();
        subjectRepository.findActiveByIdAndInstitutionId(subjectId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Subject", subjectId));

        validateTeacherOrAdminPermission(subjectId, tenantId, principal);

        SubjectEnrollment enrollment = subjectEnrollmentRepository
                .findBySubject_SubjectIdAndStudent_StudentId(subjectId, studentId)
                .orElseThrow(() -> new ResourceNotFoundException("Student is not enrolled in this subject."));

        enrollment.setStatus(ClassStatus.ACTIVE);
        subjectEnrollmentRepository.save(enrollment);

        return getSubjectDetails(subjectId, principal);
    }

    private void validateTeacherOrAdminPermission(Long subjectId, Long tenantId, UserPrincipal principal) {
        UserRole role = principal.getRole();
        if (role == UserRole.ADMIN) {
            return;
        }
        if (role == UserRole.TEACHER) {
            boolean assigned = teacherAssignmentRepository.existsAssignmentForUser(subjectId, principal.getUserId(), tenantId);
            if (!assigned) {
                throw new AccessDeniedException("Access denied: Only the assigned teacher or an administrator can manage student suspensions for this subject.");
            }
            return;
        }
        throw new AccessDeniedException("You are not authorized to suspend or activate students.");
    }


    private void validateSubjectAccess(Long subjectId, Long tenantId, UserPrincipal principal) {
        UserRole role = principal.getRole();

        if (role == null) {
            throw new AccessDeniedException("User role not available");
        }

        if (role == UserRole.STUDENT) {
            SubjectEnrollment enrollment = subjectEnrollmentRepository
                    .findBySubject_SubjectIdAndStudent_User_UserId(subjectId, principal.getUserId())
                    .orElseThrow(() -> new AccessDeniedException("Access denied: You are not enrolled in this subject"));

            if (enrollment.getStatus() == ClassStatus.SUSPENDED) {
                throw new AccessDeniedException("Access denied: You are suspended from this subject class");
            }
            return;
        }

        if (role == UserRole.TEACHER) {
            boolean assigned = teacherAssignmentRepository.existsAssignmentForUser(
                    subjectId, principal.getUserId(), tenantId);
            if (!assigned) {
                throw new AccessDeniedException("Access denied: You are not assigned to this subject");
            }
            return;
        }

        if (role == UserRole.ADMIN) {
            return;
        }

        throw new AccessDeniedException("You are not authorized to access this subject");
    }


    private Long requireTenant() {
        Long tenantId = TenantContext.get();
        if (tenantId == null) {
            log.warn("Tenant context is missing while accessing subject");
            throw new TenantMismatchException("Tenant context not available");
        }
        return tenantId;
    }
}