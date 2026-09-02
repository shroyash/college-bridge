package com.college.bridge.academic.service;

import com.college.bridge.academic.dto.*;
import com.college.bridge.academic.entity.*;
import com.college.bridge.academic.repository.AcademicLevelRepository;
import com.college.bridge.academic.repository.AcademicProgramRepository;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.academic.repository.TeacherAssignmentRepository;
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

import java.time.LocalDateTime;
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
        if (programRepository.existsByInstitution_InstitutionIdAndCodeAndDeletedFalse(tenantId, code)) {
            throw new DuplicateResourceException("Academic program with code '" + code + "' already exists.");
        }

        AcademicProgram program = AcademicProgram.builder()
                .institution(institution)
                .name(request.getName().trim())
                .code(code)
                .build();

        AcademicProgram saved = programRepository.save(program);
        return AcademicProgramResponse.from(saved);
    }

    @Transactional(readOnly = true)
    public List<AcademicProgramResponse> getPrograms() {
        Long tenantId = requireTenantId();
        return programRepository.findByInstitution_InstitutionIdAndDeletedFalse(tenantId)
                .stream()
                .map(AcademicProgramResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<AcademicProgramResponse> getProgramsByInstitutionCode(String institutionCode) {
        if (institutionCode == null || institutionCode.trim().isEmpty()) {
            throw new IllegalArgumentException("Institution code must not be empty.");
        }
        Institution institution = institutionRepository.findByCode(institutionCode.trim().toUpperCase())
                .orElseThrow(() -> new ResourceNotFoundException("Institution not found with code: " + institutionCode));

        return programRepository.findByInstitution_InstitutionIdAndDeletedFalse(institution.getInstitutionId())
                .stream()
                .map(AcademicProgramResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public AcademicProgramResponse getProgramById(Long programId) {
        Long tenantId = requireTenantId();
        AcademicProgram program = programRepository.findByProgramIdAndInstitution_InstitutionIdAndDeletedFalse(programId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic program not found with ID: " + programId));
        return AcademicProgramResponse.from(program);
    }

    @Transactional
    public void deleteProgram(Long programId) {
        Long tenantId = requireTenantId();
        AcademicProgram program = programRepository.findByProgramIdAndInstitution_InstitutionIdAndDeletedFalse(programId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic program not found with ID: " + programId));

        program.setDeleted(true);
        program.setDeletedAt(LocalDateTime.now());
        programRepository.save(program);
        log.info("Soft deleted AcademicProgram ID: {} for tenant: {}", programId, tenantId);
    }

    // --- LEVEL MANAGEMENT ---

    @Transactional
    public AcademicLevelResponse createLevel(Long programId, AcademicLevelRequest request) {
        Long tenantId = requireTenantId();
        AcademicProgram program = programRepository.findByProgramIdAndInstitution_InstitutionIdAndDeletedFalse(programId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic program not found with ID: " + programId));

        if (levelRepository.existsByProgram_ProgramIdAndLevelNumberAndDeletedFalse(programId, request.getLevelNumber())) {
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
        programRepository.findByProgramIdAndInstitution_InstitutionIdAndDeletedFalse(programId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic program not found with ID: " + programId));

        return levelRepository.findByProgram_ProgramIdAndDeletedFalse(programId)
                .stream()
                .map(AcademicLevelResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<AcademicLevelResponse> getPublicLevelsForProgram(Long programId) {
        programRepository.findByProgramIdAndDeletedFalse(programId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic program not found with ID: " + programId));

        return levelRepository.findByProgram_ProgramIdAndDeletedFalse(programId)
                .stream()
                .map(AcademicLevelResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<AcademicLevelResponse> getAllLevelsForInstitution() {
        Long tenantId = requireTenantId();
        return levelRepository.findByProgram_Institution_InstitutionIdAndDeletedFalseAndProgram_DeletedFalse(tenantId)
                .stream()
                .map(AcademicLevelResponse::from)
                .toList();
    }

    @Transactional
    public void deleteLevel(Long levelId) {
        Long tenantId = requireTenantId();
        AcademicLevel level = levelRepository.findByLevelIdAndProgram_Institution_InstitutionIdAndDeletedFalseAndProgram_DeletedFalse(levelId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic level not found with ID: " + levelId));

        int clearedCount = studentRepository.clearAcademicLevel(levelId);
        log.info("Bulk cleared academic level association for {} students.", clearedCount);

        level.setDeleted(true);
        level.setDeletedAt(LocalDateTime.now());
        levelRepository.save(level);
        log.info("Soft deleted AcademicLevel ID: {} for tenant: {}", levelId, tenantId);
    }

    // --- SUBJECT MANAGEMENT ---

    @Transactional
    public SubjectResponse createSubject(CreateSubjectRequest request) {
        Long tenantId = requireTenantId();
        AcademicLevel level = levelRepository.findByLevelIdAndProgram_Institution_InstitutionIdAndDeletedFalseAndProgram_DeletedFalse(request.getLevelId(), tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic level not found with ID: " + request.getLevelId()));

        if (subjectRepository.existsByAcademicLevel_LevelIdAndNameAndDeletedFalse(level.getLevelId(), request.getName().trim())) {
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
        AcademicLevel level = levelRepository.findByLevelIdAndProgram_Institution_InstitutionIdAndDeletedFalseAndProgram_DeletedFalse(request.getLevelId(), tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic level not found with ID: " + request.getLevelId()));

        List<SubjectResponse> createdSubjects = new ArrayList<>();
        for (BatchCreateSubjectRequest.SubjectItem item : request.getSubjects()) {
            if (subjectRepository.existsByAcademicLevel_LevelIdAndNameAndDeletedFalse(level.getLevelId(), item.getName().trim())) {
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
        levelRepository.findByLevelIdAndProgram_Institution_InstitutionIdAndDeletedFalseAndProgram_DeletedFalse(levelId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic level not found with ID: " + levelId));

        return subjectRepository.findByAcademicLevel_LevelIdAndDeletedFalse(levelId)
                .stream()
                .map(SubjectResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<SubjectResponse> getAllSubjects() {
        Long tenantId = requireTenantId();
        return subjectRepository.findByAcademicLevel_Program_Institution_InstitutionIdAndDeletedFalseAndAcademicLevel_DeletedFalseAndAcademicLevel_Program_DeletedFalse(tenantId)
                .stream()
                .map(SubjectResponse::from)
                .toList();
    }

    @Transactional
    public SubjectResponse updateSubject(Long subjectId, CreateSubjectRequest request) {
        Long tenantId = requireTenantId();
        Subject subject = subjectRepository.findBySubjectIdAndAcademicLevel_Program_Institution_InstitutionIdAndDeletedFalseAndAcademicLevel_DeletedFalseAndAcademicLevel_Program_DeletedFalse(subjectId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Subject not found with ID: " + subjectId));

        if (request.getLevelId() != null && !request.getLevelId().equals(subject.getAcademicLevel().getLevelId())) {
            AcademicLevel newLevel = levelRepository.findByLevelIdAndProgram_Institution_InstitutionIdAndDeletedFalseAndProgram_DeletedFalse(request.getLevelId(), tenantId)
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
        Subject subject = subjectRepository.findBySubjectIdAndAcademicLevel_Program_Institution_InstitutionIdAndDeletedFalseAndAcademicLevel_DeletedFalseAndAcademicLevel_Program_DeletedFalse(subjectId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Subject not found with ID: " + subjectId));

        subject.setDeleted(true);
        subject.setDeletedAt(LocalDateTime.now());
        subjectRepository.save(subject);
        log.info("Soft deleted Subject ID: {} for tenant: {}", subjectId, tenantId);
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
