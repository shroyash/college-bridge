package com.college.bridge.academic.service;

import com.college.bridge.academic.dto.SubjectResponse;
import com.college.bridge.academic.entity.AcademicClass;
import com.college.bridge.academic.entity.Faculty;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.repository.StudentRepository;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.common.exception.TenantMismatchException;
import com.college.bridge.common.tenant.TenantContext;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true, noRollbackFor = {TenantMismatchException.class, ResourceNotFoundException.class})
public class SubjectService {

    private final SubjectRepository subjectRepository;
    private final StudentRepository studentRepository;

    public SubjectResponse getSubjectById(Long subjectId) {
        Subject subject = subjectRepository.findById(subjectId)
                .orElseThrow(() -> new ResourceNotFoundException("Subject not found: " + subjectId));

        Long currentTenantId = TenantContext.get();
        if (subject.getInstitution() == null || currentTenantId == null || !subject.getInstitution().getInstitutionId().equals(currentTenantId)) {
            throw new TenantMismatchException("Subject not found or does not belong to the current institution");
        }

        return SubjectResponse.from(subject);
    }

    public List<SubjectResponse> getSubjects(Faculty faculty, Integer semester) {
        Long tenantId = TenantContext.get();
        if (tenantId == null) {
            return List.of();
        }

        return subjectRepository.findByInstitution_InstitutionIdAndFacultyAndSemester(tenantId, faculty, semester)
                .stream()
                .map(SubjectResponse::from)
                .toList();
    }

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

    public List<SubjectResponse> getSubjectsForStudent(Long studentId) {
        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new EntityNotFoundException("Student not found: " + studentId));

        Long currentTenantId = TenantContext.get();
        if (student.getUser().getInstitution() != null && currentTenantId != null
                && !student.getUser().getInstitution().getInstitutionId().equals(currentTenantId)) {
            throw new TenantMismatchException("Student does not belong to current institution");
        }

        AcademicClass academicClass = student.getAcademicClass();
        if (academicClass == null || currentTenantId == null) {
            return List.of();
        }

        return subjectRepository.findByInstitution_InstitutionIdAndFacultyAndSemester(
                        currentTenantId,
                        academicClass.getFaculty(),
                        academicClass.getSemester()
                ).stream()
                .map(SubjectResponse::from)
                .toList();
    }
}