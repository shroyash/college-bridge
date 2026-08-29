package com.college.bridge.academic.service;

import com.college.bridge.academic.dto.*;
import com.college.bridge.academic.entity.*;
import com.college.bridge.academic.repository.AcademicLevelRepository;
import com.college.bridge.academic.repository.AcademicProgramRepository;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.academic.repository.TeacherAssignmentRepository;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.repository.StudentRepository;
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

    private final AcademicProgramRepository programRepository;
    private final AcademicLevelRepository levelRepository;
    private final SubjectRepository subjectRepository;
    private final InstitutionRepository institutionRepository;
    private final StudentRepository studentRepository;
    private final TeacherAssignmentRepository teacherAssignmentRepository;

    // --- PROGRAM MANAGEMENT ---

    @Transactional
    public AcademicProgramResponse createProgram(AcademicProgramRequest request) {
        Long tenantId = requireTenantId();
        Institution institution = getInstitution(tenantId);

        String code = request.getCode().trim().toUpperCase();
        if (programRepository.existsByInstitution_InstitutionIdAndCode(tenantId, code)) {
            throw new DuplicateResourceException("Academic program with code '" + code + "' already exists.");
        }

        AcademicProgram program = AcademicProgram.builder()
                .institution(institution)
                .name(request.getName().trim())
                .code(code)
                .build();

        AcademicProgram saved = programRepository.save(program);
        log.info("Created AcademicProgram ID: {} ({}) for tenant: {}", saved.getProgramId(), saved.getCode(), tenantId);
        return AcademicProgramResponse.from(saved);
    }

    @Transactional(readOnly = true)
    public List<AcademicProgramResponse> getPrograms() {
        Long tenantId = requireTenantId();
        return programRepository.findByInstitution_InstitutionId(tenantId)
                .stream()
                .map(AcademicProgramResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public AcademicProgramResponse getProgramById(Long programId) {
        Long tenantId = requireTenantId();
        AcademicProgram program = programRepository.findByProgramIdAndInstitution_InstitutionId(programId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic program not found with ID: " + programId));
        return AcademicProgramResponse.from(program);
    }

    @Transactional
    public void deleteProgram(Long programId) {
        Long tenantId = requireTenantId();
        AcademicProgram program = programRepository.findByProgramIdAndInstitution_InstitutionId(programId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic program not found with ID: " + programId));
        programRepository.delete(program);
        log.info("Deleted AcademicProgram ID: {} for tenant: {}", programId, tenantId);
    }

    // --- LEVEL MANAGEMENT ---

    @Transactional
    public AcademicLevelResponse createLevel(Long programId, AcademicLevelRequest request) {
        Long tenantId = requireTenantId();
        AcademicProgram program = programRepository.findByProgramIdAndInstitution_InstitutionId(programId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic program not found with ID: " + programId));

        if (levelRepository.existsByProgram_ProgramIdAndLevelNumber(programId, request.getLevelNumber())) {
            throw new DuplicateResourceException("Academic level number " + request.getLevelNumber() + " already exists for program " + program.getCode());
        }

        AcademicLevel level = AcademicLevel.builder()
                .program(program)
                .name(request.getName().trim())
                .levelNumber(request.getLevelNumber())
                .type(request.getType())
                .build();

        AcademicLevel saved = levelRepository.save(level);
        log.info("Created AcademicLevel ID: {} ({}) for program: {}", saved.getLevelId(), saved.getName(), programId);
        return AcademicLevelResponse.from(saved);
    }

    @Transactional(readOnly = true)
    public List<AcademicLevelResponse> getLevelsForProgram(Long programId) {
        Long tenantId = requireTenantId();
        programRepository.findByProgramIdAndInstitution_InstitutionId(programId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic program not found with ID: " + programId));

        return levelRepository.findByProgram_ProgramId(programId)
                .stream()
                .map(AcademicLevelResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<AcademicLevelResponse> getAllLevelsForInstitution() {
        Long tenantId = requireTenantId();
        return levelRepository.findByProgram_Institution_InstitutionId(tenantId)
                .stream()
                .map(AcademicLevelResponse::from)
                .toList();
    }

    @Transactional
    public void deleteLevel(Long levelId) {
        Long tenantId = requireTenantId();
        AcademicLevel level = levelRepository.findByLevelIdAndProgram_Institution_InstitutionId(levelId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic level not found with ID: " + levelId));

        List<Student> students = studentRepository.findByAcademicLevel_LevelId(levelId);
        for (Student s : students) {
            s.setAcademicLevel(null);
            studentRepository.save(s);
        }

        levelRepository.delete(level);
        log.info("Deleted AcademicLevel ID: {} for tenant: {}", levelId, tenantId);
    }

    // --- SUBJECT MANAGEMENT ---

    @Transactional
    public SubjectResponse createSubject(CreateSubjectRequest request) {
        Long tenantId = requireTenantId();
        AcademicLevel level = levelRepository.findByLevelIdAndProgram_Institution_InstitutionId(request.getLevelId(), tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic level not found with ID: " + request.getLevelId()));

        if (subjectRepository.existsByAcademicLevel_LevelIdAndName(level.getLevelId(), request.getName().trim())) {
            throw new DuplicateResourceException("Subject '" + request.getName() + "' already exists for level " + level.getName());
        }

        Subject subject = Subject.builder()
                .academicLevel(level)
                .name(request.getName().trim())
                .code(request.getCode() != null ? request.getCode().trim() : null)
                .creditHours(request.getCreditHours() != null ? request.getCreditHours() : 3)
                .fcmTopicId(request.getFcmTopicId())
                .build();

        Subject saved = subjectRepository.save(subject);
        log.info("Created Subject ID: {} ('{}') for level: {}", saved.getSubjectId(), saved.getName(), level.getLevelId());
        return SubjectResponse.from(saved);
    }

    @Transactional
    public List<SubjectResponse> batchCreateSubjects(BatchCreateSubjectRequest request) {
        Long tenantId = requireTenantId();
        AcademicLevel level = levelRepository.findByLevelIdAndProgram_Institution_InstitutionId(request.getLevelId(), tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic level not found with ID: " + request.getLevelId()));

        List<SubjectResponse> createdSubjects = new ArrayList<>();
        for (BatchCreateSubjectRequest.SubjectItem item : request.getSubjects()) {
            if (subjectRepository.existsByAcademicLevel_LevelIdAndName(level.getLevelId(), item.getName().trim())) {
                log.warn("Skipping duplicate subject creation: '{}' for level {}", item.getName(), level.getLevelId());
                continue;
            }

            Subject subject = Subject.builder()
                    .academicLevel(level)
                    .name(item.getName().trim())
                    .code(item.getCode() != null ? item.getCode().trim() : null)
                    .creditHours(item.getCreditHours() != null ? item.getCreditHours() : 3)
                    .build();

            Subject saved = subjectRepository.save(subject);
            createdSubjects.add(SubjectResponse.from(saved));
        }

        return createdSubjects;
    }

    @Transactional(readOnly = true)
    public List<SubjectResponse> getSubjectsForLevel(Long levelId) {
        Long tenantId = requireTenantId();
        levelRepository.findByLevelIdAndProgram_Institution_InstitutionId(levelId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic level not found with ID: " + levelId));

        return subjectRepository.findByAcademicLevel_LevelId(levelId)
                .stream()
                .map(SubjectResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<SubjectResponse> getAllSubjects() {
        Long tenantId = requireTenantId();
        return subjectRepository.findByAcademicLevel_Program_Institution_InstitutionId(tenantId)
                .stream()
                .map(SubjectResponse::from)
                .toList();
    }

    @Transactional
    public SubjectResponse updateSubject(Long subjectId, CreateSubjectRequest request) {
        Long tenantId = requireTenantId();
        Subject subject = subjectRepository.findBySubjectIdAndAcademicLevel_Program_Institution_InstitutionId(subjectId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Subject not found with ID: " + subjectId));

        if (request.getLevelId() != null && !request.getLevelId().equals(subject.getAcademicLevel().getLevelId())) {
            AcademicLevel newLevel = levelRepository.findByLevelIdAndProgram_Institution_InstitutionId(request.getLevelId(), tenantId)
                    .orElseThrow(() -> new ResourceNotFoundException("Academic level not found with ID: " + request.getLevelId()));
            subject.setAcademicLevel(newLevel);
        }

        subject.setName(request.getName().trim());
        if (request.getCode() != null) {
            subject.setCode(request.getCode().trim());
        }
        if (request.getCreditHours() != null) {
            subject.setCreditHours(request.getCreditHours());
        }
        if (request.getFcmTopicId() != null) {
            subject.setFcmTopicId(request.getFcmTopicId());
        }

        Subject saved = subjectRepository.save(subject);
        return SubjectResponse.from(saved);
    }

    @Transactional
    public void deleteSubject(Long subjectId) {
        Long tenantId = requireTenantId();
        Subject subject = subjectRepository.findBySubjectIdAndAcademicLevel_Program_Institution_InstitutionId(subjectId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Subject not found with ID: " + subjectId));

        subjectRepository.delete(subject);
        log.info("Deleted subject ID: {} for tenant: {}", subjectId, tenantId);
    }

    // --- STUDENT LEVEL MAPPING ---

    @Transactional
    public ClassStudentResponse addStudentToLevel(Long levelId, Long studentId) {
        Long tenantId = requireTenantId();
        AcademicLevel level = levelRepository.findByLevelIdAndProgram_Institution_InstitutionId(levelId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic level not found with ID: " + levelId));

        Student student = studentRepository.findById(studentId)
                .filter(s -> s.getUser() != null && s.getUser().getInstitution() != null && s.getUser().getInstitution().getInstitutionId().equals(tenantId))
                .orElseThrow(() -> new ResourceNotFoundException("Student not found or access denied: " + studentId));

        student.setAcademicLevel(level);
        Student saved = studentRepository.save(student);

        return ClassStudentResponse.builder()
                .studentId(saved.getStudentId())
                .userId(saved.getUser().getUserId())
                .fullName(saved.getUser().getFullName())
                .email(saved.getUser().getEmail())
                .status(saved.getUser().getStatus() != null ? saved.getUser().getStatus().name() : "ACTIVE")
                .build();
    }

    @Transactional
    public void removeStudentFromLevel(Long levelId, Long studentId) {
        Long tenantId = requireTenantId();
        levelRepository.findByLevelIdAndProgram_Institution_InstitutionId(levelId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic level not found with ID: " + levelId));

        Student student = studentRepository.findById(studentId)
                .filter(s -> s.getUser() != null && s.getUser().getInstitution() != null && s.getUser().getInstitution().getInstitutionId().equals(tenantId))
                .orElseThrow(() -> new ResourceNotFoundException("Student not found or access denied: " + studentId));

        if (student.getAcademicLevel() != null && student.getAcademicLevel().getLevelId().equals(levelId)) {
            student.setAcademicLevel(null);
            studentRepository.save(student);
        }
    }

    @Transactional(readOnly = true)
    public List<ClassStudentResponse> getUnassignedStudents() {
        Long tenantId = requireTenantId();
        List<Student> unassigned = studentRepository.findByUser_Institution_InstitutionIdAndAcademicLevelIsNull(tenantId);
        return unassigned.stream().map(s -> ClassStudentResponse.builder()
                .studentId(s.getStudentId())
                .userId(s.getUser() != null ? s.getUser().getUserId() : null)
                .fullName(s.getUser() != null ? s.getUser().getFullName() : "Unknown")
                .email(s.getUser() != null ? s.getUser().getEmail() : "")
                .status(s.getUser() != null && s.getUser().getStatus() != null ? s.getUser().getStatus().name() : "ACTIVE")
                .build()).toList();
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
}
