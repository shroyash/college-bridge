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

    @Transactional(readOnly = true)
    public List<SubjectResponse> getTeacherAssignedSubjects(Long teacherId) {
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher not found with ID: " + teacherId));

        Long tenantId = com.college.bridge.common.tenant.TenantContext.get();
        List<TeacherAssignment> assignments = (tenantId != null)
                ? teacherAssignmentRepository.findByTeacher_TeacherIdAndSubject_AcademicLevel_Program_Institution_InstitutionId(teacher.getTeacherId(), tenantId)
                : teacherAssignmentRepository.findByTeacherTeacherId(teacher.getTeacherId());

        return assignments.stream()
                .map(ta -> SubjectResponse.from(ta.getSubject()))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<AcademicLevelResponse> getTeacherClasses(Long teacherId) {
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher not found with ID: " + teacherId));

        Long tenantId = com.college.bridge.common.tenant.TenantContext.get();
        List<TeacherAssignment> assignments = (tenantId != null)
                ? teacherAssignmentRepository.findByTeacher_TeacherIdAndSubject_AcademicLevel_Program_Institution_InstitutionId(teacher.getTeacherId(), tenantId)
                : teacherAssignmentRepository.findByTeacherTeacherId(teacher.getTeacherId());

        List<AcademicLevel> levels = assignments.stream()
                .map(ta -> ta.getSubject().getAcademicLevel())
                .filter(java.util.Objects::nonNull)
                .distinct()
                .toList();

        return levels.stream().map(AcademicLevelResponse::from).toList();
    }
}
