package com.college.bridge.academic.service;

import com.college.bridge.academic.dto.AcademicLevelResponse;
import com.college.bridge.academic.dto.SubjectResponse;
import com.college.bridge.academic.entity.AcademicLevel;
import com.college.bridge.academic.mapper.AcademicLevelMapper;
import com.college.bridge.academic.mapper.SubjectMapper;
import com.college.bridge.academic.repository.TeacherAssignmentRepository;
import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.repository.TeacherRepository;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.common.exception.TenantMismatchException;
import com.college.bridge.common.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class TeacherAcademicService {

    private final TeacherRepository teacherRepository;
    private final TeacherAssignmentRepository teacherAssignmentRepository;
    private final SubjectMapper subjectMapper;
    private final AcademicLevelMapper academicLevelMapper;

    /**
     * Returns all subjects assigned to the given teacher, scoped to the current tenant.
     */
    @Transactional(readOnly = true)
    public List<SubjectResponse> getTeacherAssignedSubjects(Long teacherId) {
        Long tenantId = requireTenant();

        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher not found with ID: " + teacherId));

        return teacherAssignmentRepository
                .findActiveByTeacherIdAndInstitutionId(teacher.getTeacherId(), tenantId)
                .stream()
                .map(ta -> {
                    String teacherName = (ta.getTeacher() != null && ta.getTeacher().getUser() != null)
                            ? ta.getTeacher().getUser().getFullName()
                            : null;
                    return subjectMapper.toResponse(ta.getSubject(), teacherName);
                })
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
                .findActiveByTeacherIdAndInstitutionId(teacher.getTeacherId(), tenantId)
                .stream()
                .map(ta -> ta.getSubject().getAcademicLevel())
                .filter(java.util.Objects::nonNull)
                .distinct()
                .toList();

        return academicLevelMapper.toResponseList(levels);
    }

    private Long requireTenant() {
        Long tenantId = TenantContext.get();
        if (tenantId == null) {
            throw new TenantMismatchException("Tenant context is missing.");
        }
        return tenantId;
    }
}
