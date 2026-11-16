package com.college.bridge.academic.service;

import com.college.bridge.academic.dto.AssignTeacherSubjectsRequest;
import com.college.bridge.academic.dto.TeacherAssignmentResponse;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.entity.TeacherAssignment;
import com.college.bridge.academic.exception.TeacherAssignmentAlreadyExistsException;
import com.college.bridge.academic.mapper.TeacherAssignmentMapper;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.academic.repository.TeacherAssignmentRepository;
import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.repository.TeacherRepository;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.common.exception.TenantMismatchException;
import com.college.bridge.common.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TeacherAssignmentService {

    private final TeacherRepository teacherRepository;
    private final SubjectRepository subjectRepository;
    private final TeacherAssignmentRepository teacherAssignmentRepository;
    private final TeacherAssignmentMapper mapper;


    @Transactional
    public List<TeacherAssignmentResponse> assignSubjects(
            Long teacherId,
            AssignTeacherSubjectsRequest request
    ) {
        Long tenantId = requireTenantId();

        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseGet(() -> teacherRepository.findByUser_UserId(teacherId)
                        .orElseThrow(() -> new ResourceNotFoundException("Teacher not found with ID: " + teacherId)));

        validateTeacherBelongsToTenant(teacher, tenantId);

        List<Long> subjectIds = request.getSubjectIds().stream().distinct().toList();

        List<Subject> subjects = subjectRepository.findBySubjectIdsAndTenant(subjectIds, tenantId);
        if (subjects.size() != subjectIds.size()) {
            throw new ResourceNotFoundException(
                    "One or more selected subjects do not exist within your institution."
            );
        }

        List<TeacherAssignment> existingAssignments =
                teacherAssignmentRepository.findBySubject_SubjectIdInAndTenantId(subjectIds, tenantId);


        List<String> alreadyAssignedSubjects = existingAssignments.stream()
                .map(assignment -> assignment.getSubject().getName())
                .toList();

        if (!alreadyAssignedSubjects.isEmpty()) {
            throw new TeacherAssignmentAlreadyExistsException(
                    "Teacher already assigned to: " +
                            String.join(", ", alreadyAssignedSubjects)
            );
        }

        List<TeacherAssignment> assignments = subjects.stream()
                .map(subject -> mapper.toEntity(teacher, subject))
                .toList();

        teacherAssignmentRepository.saveAll(assignments);

        return assignments.stream()
                .map(mapper::toResponse)
                .toList();
    }


    @Transactional(readOnly = true)
    public List<TeacherAssignmentResponse> getAssignments(Long teacherId) {
        Long tenantId = requireTenantId();

        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseGet(() -> teacherRepository.findByUser_UserId(teacherId)
                        .orElseThrow(() -> new ResourceNotFoundException("Teacher not found with ID: " + teacherId)));

        validateTeacherBelongsToTenant(teacher, tenantId);

        return teacherAssignmentRepository
                .findActiveByTeacherIdAndInstitutionId(teacher.getTeacherId(), tenantId)
                .stream()
                .map(mapper::toResponse)
                .toList();
    }


    @Transactional
    public List<TeacherAssignmentResponse> replaceAssignments(
            Long teacherId,
            AssignTeacherSubjectsRequest request
    ) {
        Long tenantId = requireTenantId();
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseGet(() -> teacherRepository.findByUser_UserId(teacherId)
                        .orElseThrow(() -> new ResourceNotFoundException("Teacher not found with ID: " + teacherId)));
        validateTeacherBelongsToTenant(teacher, tenantId);

        teacherAssignmentRepository.deleteByTeacherTeacherId(teacher.getTeacherId());
        teacherAssignmentRepository.flush();

        return assignSubjects(teacher.getTeacherId(), request);
    }


    @Transactional
    public void deleteAssignment(Long assignmentId) {
        Long tenantId = requireTenantId();

        TeacherAssignment assignment = teacherAssignmentRepository
                .findByAssignmentIdAndTenant(assignmentId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Assignment not found with ID: " + assignmentId));

        teacherAssignmentRepository.delete(assignment);
    }

    // ── Private Helpers ───────────────────────────────────────────────────────

    private Long requireTenantId() {
        Long tenantId = TenantContext.get();
        if (tenantId == null) {
            throw new TenantMismatchException("Tenant context is missing.");
        }
        return tenantId;
    }


    private void validateTeacherBelongsToTenant(Teacher teacher, Long tenantId) {
        Long teacherTenantId = (teacher.getUser() != null && teacher.getUser().getInstitution() != null)
                ? teacher.getUser().getInstitution().getInstitutionId()
                : null;
        if (teacherTenantId == null || !teacherTenantId.equals(tenantId)) {
            throw new AccessDeniedException("Teacher does not belong to your institution.");
        }
    }
}