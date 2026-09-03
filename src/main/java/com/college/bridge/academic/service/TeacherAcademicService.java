package com.college.bridge.academic.service;

import com.college.bridge.academic.dto.*;
import com.college.bridge.academic.entity.AcademicLevel;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.entity.TeacherAssignment;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.academic.repository.TeacherAssignmentRepository;
import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.repository.TeacherRepository;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.common.exception.TenantMismatchException;
import com.college.bridge.common.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class TeacherAcademicService {

    private final TeacherRepository teacherRepository;
    private final TeacherAssignmentRepository teacherAssignmentRepository;
    private final SubjectRepository subjectRepository;

    /**
     * Returns all subjects assigned to the given teacher, scoped to the current tenant.
     * <p>
     * I-3 FIX: removed the null-tenant fallback that previously fell through to an
     * unscoped query. Tenant context is always required; a missing context is a
     * configuration/security error, not a valid runtime path.
     */
    @Transactional(readOnly = true)
    public List<SubjectResponse> getTeacherAssignedSubjects(Long teacherId) {
        Long tenantId = requireTenant();

        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher not found with ID: " + teacherId));

        return teacherAssignmentRepository
                .findByTeacher_TeacherIdAndSubject_AcademicLevel_Program_Institution_InstitutionId(
                        teacher.getTeacherId(), tenantId)
                .stream()
                .map(ta -> SubjectResponse.from(ta.getSubject()))
                .toList();
    }

    /**
     * Returns the distinct academic levels for which the teacher has at least one subject assignment,
     * scoped to the current tenant.
     */
    @Transactional(readOnly = true)
    public List<AcademicLevelResponse> getTeacherClasses(Long teacherId) {
        Long tenantId = requireTenant();

        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher not found with ID: " + teacherId));

        List<AcademicLevel> levels = teacherAssignmentRepository
                .findByTeacher_TeacherIdAndSubject_AcademicLevel_Program_Institution_InstitutionId(
                        teacher.getTeacherId(), tenantId)
                .stream()
                .map(ta -> ta.getSubject().getAcademicLevel())
                .filter(java.util.Objects::nonNull)
                .distinct()
                .toList();

        return levels.stream().map(AcademicLevelResponse::from).toList();
    }

    private Long requireTenant() {
        Long tenantId = TenantContext.get();
        if (tenantId == null) {
            throw new TenantMismatchException("Tenant context is missing.");
        }
        return tenantId;
    }
}
