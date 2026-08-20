package com.college.bridge.academic.service;

import com.college.bridge.academic.dto.SubjectResponse;
import com.college.bridge.academic.entity.AcademicClass;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.repository.StudentRepository;
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
@Transactional(noRollbackFor = { TenantMismatchException.class, ResourceNotFoundException.class })
public class SubjectService {

    private final SubjectRepository subjectRepository;
    private final StudentRepository studentRepository;

    @Transactional(readOnly = true, noRollbackFor = { TenantMismatchException.class, ResourceNotFoundException.class })
    public SubjectResponse getSubjectById(Long subjectId) {
        Subject subject = subjectRepository.findById(subjectId)
                .orElseThrow(() -> new ResourceNotFoundException("Subject", subjectId));

        Long currentTenantId = TenantContext.get();
        if (subject.getInstitution() == null || currentTenantId == null
                || !subject.getInstitution().getInstitutionId().equals(currentTenantId)) {
            throw new TenantMismatchException("Subject not found or does not belong to current institution");
        }

        return SubjectResponse.from(subject);
    }

    @Transactional(readOnly = true, noRollbackFor = { TenantMismatchException.class, ResourceNotFoundException.class })
    public List<SubjectResponse> getSubjects(String faculty, Integer semester) {
        Long tenantId = TenantContext.get();
        if (tenantId == null) {
            return List.of();
        }

        return subjectRepository.findByInstitution_InstitutionIdAndFacultyAndSemester(tenantId, faculty, semester)
                .stream()
                .map(SubjectResponse::from)
                .toList();
    }

    @Transactional(readOnly = true, noRollbackFor = { TenantMismatchException.class, ResourceNotFoundException.class })
    public List<SubjectResponse> getAllSubjects() {
        Long tenantId = TenantContext.get();
        if (tenantId == null) {
            return List.of();
        }

        return subjectRepository.findByInstitution_InstitutionId(tenantId)
                .stream()
                .map(SubjectResponse::from)
                .toList();
    }

    @Transactional(readOnly = true, noRollbackFor = { TenantMismatchException.class, ResourceNotFoundException.class })
    public List<SubjectResponse> searchSubjects(String name) {
        Long tenantId = TenantContext.get();
        if (tenantId == null) {
            return List.of();
        }

        return subjectRepository.findByInstitution_InstitutionIdAndNameContainingIgnoreCase(tenantId, name)
                .stream()
                .map(SubjectResponse::from)
                .toList();
    }

    @Transactional(readOnly = true, noRollbackFor = { TenantMismatchException.class, ResourceNotFoundException.class })
    public List<SubjectResponse> getSubjectsForStudent(Long studentId) {
        Long tenantId = TenantContext.get();
        if (tenantId == null) {
            return List.of();
        }

        Student student = studentRepository.findByStudentId(studentId)
                .orElseThrow(() -> new ResourceNotFoundException("Student not found"));

        AcademicClass academicClass = student.getAcademicClass();
        if (academicClass == null) {
            return List.of();
        }

        return subjectRepository.findByInstitution_InstitutionIdAndFacultyAndSemester(
                tenantId,
                academicClass.getFaculty(),
                academicClass.getSemester())
                .stream()
                .map(SubjectResponse::from)
                .toList();
    }
}