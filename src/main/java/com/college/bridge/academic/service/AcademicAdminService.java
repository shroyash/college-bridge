package com.college.bridge.academic.service;

import com.college.bridge.academic.dto.*;
import com.college.bridge.academic.entity.AcademicClass;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.repository.AcademicClassRepository;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.common.exception.DuplicateResourceException;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.common.exception.TenantMismatchException;
import com.college.bridge.common.tenant.TenantContext;
import com.college.bridge.institution.entity.Institution;
import com.college.bridge.institution.repository.InstitutionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class AcademicAdminService {

    private final AcademicClassRepository academicClassRepository;
    private final SubjectRepository subjectRepository;
    private final InstitutionRepository institutionRepository;

    private static final String[] ORDINALS = {
        "", "First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh", "Eighth", "Ninth", "Tenth", "Eleventh", "Twelfth"
    };

    @Transactional
    public AcademicClassResponse createAcademicClass(CreateAcademicClassRequest request) {
        Long tenantId = requireTenantId();
        Institution institution = getInstitution(tenantId);

        if (academicClassRepository.existsByInstitution_InstitutionIdAndFacultyAndSemester(tenantId, request.getFaculty(), request.getSemester())) {
            throw new DuplicateResourceException("Academic class for " + request.getFaculty() + " semester " + request.getSemester() + " already exists.");
        }

        String displayName = request.getDisplayName();
        if (displayName == null || displayName.isBlank()) {
            displayName = formatAcademicClassDisplayName(request.getFaculty(), request.getSemester());
        }

        AcademicClass academicClass = AcademicClass.builder()
                .institution(institution)
                .faculty(request.getFaculty())
                .semester(request.getSemester())
                .displayName(displayName)
                .build();

        AcademicClass saved = academicClassRepository.save(academicClass);
        log.info("Created AcademicClass ID: {} ({}) for institution: {}", saved.getClassId(), saved.getDisplayName(), tenantId);
        return AcademicClassResponse.from(saved);
    }

    @Transactional(readOnly = true)
    public List<String> getInstitutionFaculties() {
        Long tenantId = requireTenantId();
        return academicClassRepository.findDistinctFacultiesByInstitutionId(tenantId);
    }

    @Transactional(readOnly = true)
    public List<AcademicClassResponse> getAcademicClasses() {
        Long tenantId = requireTenantId();
        return academicClassRepository.findByInstitution_InstitutionId(tenantId)
                .stream()
                .map(AcademicClassResponse::from)
                .toList();
    }

    @Transactional
    public SubjectResponse createSubject(CreateSubjectRequest request) {
        Long tenantId = requireTenantId();
        Institution institution = getInstitution(tenantId);

        if (subjectRepository.existsByInstitution_InstitutionIdAndNameAndFacultyAndSemester(
                tenantId, request.getName().trim(), request.getFaculty(), request.getSemester())) {
            throw new DuplicateResourceException("Subject '" + request.getName() + "' already exists for " + request.getFaculty() + " semester " + request.getSemester());
        }

        // Ensure AcademicClass exists for this faculty and semester
        ensureAcademicClassExists(institution, request.getFaculty(), request.getSemester());

        Subject subject = Subject.builder()
                .institution(institution)
                .name(request.getName().trim())
                .faculty(request.getFaculty())
                .semester(request.getSemester())
                .creditHours(request.getCreditHours() != null ? request.getCreditHours() : 3)
                .build();

        Subject saved = subjectRepository.save(subject);
        log.info("Created Subject ID: {} ('{}') for institution: {}", saved.getSubjectId(), saved.getName(), tenantId);
        return SubjectResponse.from(saved);
    }

    @Transactional
    public List<SubjectResponse> batchCreateSubjects(BatchCreateSubjectRequest request) {
        Long tenantId = requireTenantId();
        Institution institution = getInstitution(tenantId);

        // Ensure AcademicClass exists
        ensureAcademicClassExists(institution, request.getFaculty(), request.getSemester());

        List<SubjectResponse> createdSubjects = new ArrayList<>();
        for (BatchCreateSubjectRequest.SubjectItem item : request.getSubjects()) {
            if (subjectRepository.existsByInstitution_InstitutionIdAndNameAndFacultyAndSemester(
                    tenantId, item.getName().trim(), request.getFaculty(), request.getSemester())) {
                log.warn("Skipping duplicate subject creation: '{}' for {} sem {}", item.getName(), request.getFaculty(), request.getSemester());
                continue;
            }

            Subject subject = Subject.builder()
                    .institution(institution)
                    .name(item.getName().trim())
                    .faculty(request.getFaculty())
                    .semester(request.getSemester())
                    .creditHours(item.getCreditHours() != null ? item.getCreditHours() : 3)
                    .build();

            Subject saved = subjectRepository.save(subject);
            createdSubjects.add(SubjectResponse.from(saved));
        }

        log.info("Batch created {} subjects for {} semester {} in institution: {}", createdSubjects.size(), request.getFaculty(), request.getSemester(), tenantId);
        return createdSubjects;
    }

    @Transactional(readOnly = true)
    public List<SubjectResponse> getSubjects(String faculty, Integer semester) {
        Long tenantId = requireTenantId();

        List<Subject> subjects;
        if (faculty != null && semester != null) {
            subjects = subjectRepository.findByInstitution_InstitutionIdAndFacultyAndSemester(tenantId, faculty, semester);
        } else {
            subjects = subjectRepository.findByInstitution_InstitutionId(tenantId);
        }

        return subjects.stream().map(SubjectResponse::from).toList();
    }

    @Transactional
    public void deleteSubject(Long subjectId) {
        Long tenantId = requireTenantId();
        Subject subject = subjectRepository.findBySubjectIdAndInstitution_InstitutionId(subjectId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Subject not found or access denied: " + subjectId));

        subjectRepository.delete(subject);
        log.info("Deleted subject ID: {} from institution: {}", subjectId, tenantId);
    }

    @Transactional
    public SubjectResponse updateSubject(Long subjectId, CreateSubjectRequest request) {
        Long tenantId = requireTenantId();
        Subject subject = subjectRepository.findBySubjectIdAndInstitution_InstitutionId(subjectId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Subject not found or access denied: " + subjectId));

        subject.setName(request.getName().trim());
        subject.setFaculty(request.getFaculty());
        subject.setSemester(request.getSemester());
        if (request.getCreditHours() != null) {
            subject.setCreditHours(request.getCreditHours());
        }

        Subject saved = subjectRepository.save(subject);
        log.info("Updated subject ID: {} in institution: {}", subjectId, tenantId);
        return SubjectResponse.from(saved);
    }

    @Transactional
    public AcademicClassResponse updateAcademicClass(Long classId, CreateAcademicClassRequest request) {
        Long tenantId = requireTenantId();
        AcademicClass academicClass = academicClassRepository.findById(classId)
                .filter(ac -> ac.getInstitution().getInstitutionId().equals(tenantId))
                .orElseThrow(() -> new ResourceNotFoundException("Academic class not found or access denied: " + classId));

        academicClass.setFaculty(request.getFaculty());
        academicClass.setSemester(request.getSemester());
        if (request.getDisplayName() != null && !request.getDisplayName().isBlank()) {
            academicClass.setDisplayName(request.getDisplayName().trim());
        } else {
            academicClass.setDisplayName(formatAcademicClassDisplayName(request.getFaculty(), request.getSemester()));
        }

        AcademicClass saved = academicClassRepository.save(academicClass);
        log.info("Updated AcademicClass ID: {} ({}) for institution: {}", saved.getClassId(), saved.getDisplayName(), tenantId);
        return AcademicClassResponse.from(saved);
    }


    private void ensureAcademicClassExists(Institution institution, String faculty, Integer semester) {
        if (!academicClassRepository.existsByInstitution_InstitutionIdAndFacultyAndSemester(institution.getInstitutionId(), faculty, semester)) {
            String displayName = formatAcademicClassDisplayName(faculty, semester);
            AcademicClass newClass = AcademicClass.builder()
                    .institution(institution)
                    .faculty(faculty)
                    .semester(semester)
                    .displayName(displayName)
                    .build();
            academicClassRepository.save(newClass);
            log.info("Auto-created AcademicClass ID: {} ({}) for institution: {}", newClass.getClassId(), displayName, institution.getInstitutionId());
        }
    }

    private Long requireTenantId() {
        Long tenantId = TenantContext.get();
        if (tenantId == null) {
            throw new TenantMismatchException("Tenant context missing. Institution Admin must belong to an institution.");
        }
        return tenantId;
    }

    private Institution getInstitution(Long tenantId) {
        return institutionRepository.findById(tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Institution not found with ID: " + tenantId));
    }

    private String formatAcademicClassDisplayName(String faculty, Integer semester) {
        String ordinal = (semester != null && semester > 0 && semester < ORDINALS.length) ? ORDINALS[semester] : semester + "th";
        return faculty + " " + ordinal + " Semester";
    }
}
