package com.college.bridge.academic.service;

import com.college.bridge.academic.dto.*;
import com.college.bridge.academic.entity.*;
import com.college.bridge.academic.mapper.AcademicLevelMapper;
import com.college.bridge.academic.mapper.AcademicProgramMapper;
import com.college.bridge.academic.mapper.SubjectMapper;
import com.college.bridge.academic.repository.AcademicLevelRepository;
import com.college.bridge.academic.repository.AcademicProgramRepository;
import com.college.bridge.academic.repository.SubjectRepository;
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
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AcademicAdminService {

    private final AcademicProgramRepository programRepository;
    private final AcademicLevelRepository levelRepository;
    private final SubjectRepository subjectRepository;
    private final InstitutionRepository institutionRepository;
    private final StudentRepository studentRepository;
    private final AcademicProgramMapper programMapper;
    private final AcademicLevelMapper levelMapper;
    private final SubjectMapper subjectMapper;

    // ── Program Management ────────────────────────────────────────────────────

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
        return programMapper.toResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<AcademicProgramResponse> getPrograms() {
        Long tenantId = requireTenantId();
        return programMapper.toResponseList(programRepository.findByInstitution_InstitutionIdAndDeletedFalse(tenantId));
    }

    @Transactional(readOnly = true)
    public List<AcademicProgramResponse> getProgramsByInstitutionCode(String institutionCode) {
        if (institutionCode == null || institutionCode.trim().isEmpty()) {
            throw new IllegalArgumentException("Institution code must not be empty.");
        }
        Institution institution = institutionRepository.findByCode(institutionCode.trim().toUpperCase())
                .orElseThrow(() -> new ResourceNotFoundException("Institution not found with code: " + institutionCode));

        return programMapper.toResponseList(programRepository.findByInstitution_InstitutionIdAndDeletedFalse(institution.getInstitutionId()));
    }

    @Transactional(readOnly = true)
    public AcademicProgramResponse getProgramById(Long programId) {
        Long tenantId = requireTenantId();
        AcademicProgram program = programRepository
                .findByProgramIdAndInstitution_InstitutionIdAndDeletedFalse(programId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic program not found with ID: " + programId));
        return programMapper.toResponse(program);
    }

    @Transactional
    public void deleteProgram(Long programId) {
        Long tenantId = requireTenantId();
        AcademicProgram program = programRepository
                .findByProgramIdAndInstitution_InstitutionIdAndDeletedFalse(programId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic program not found with ID: " + programId));

        LocalDateTime now = LocalDateTime.now();

        List<Long> levelIds = levelRepository.findLevelIdsByProgramId(programId);

        if (!levelIds.isEmpty()) {
            subjectRepository.softDeleteByLevelIds(levelIds, now);
            for (Long levelId : levelIds) {
                studentRepository.clearAcademicLevel(levelId);
            }
            levelRepository.softDeleteByProgramId(programId, now);
        }
        program.setDeleted(true);
        program.setDeletedAt(now);
        programRepository.save(program);
    }

    // ── Level Management ──────────────────────────────────────────────────────

    @Transactional
    public AcademicLevelResponse createLevel(Long programId, AcademicLevelRequest request) {
        Long tenantId = requireTenantId();
        AcademicProgram program = programRepository
                .findByProgramIdAndInstitution_InstitutionIdAndDeletedFalse(programId, tenantId)
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
        return levelMapper.toResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<AcademicLevelResponse> getLevelsForProgram(Long programId) {
        Long tenantId = requireTenantId();
        programRepository.findByProgramIdAndInstitution_InstitutionIdAndDeletedFalse(programId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic program not found with ID: " + programId));

        return levelMapper.toResponseList(levelRepository.findByProgram_ProgramIdAndDeletedFalse(programId));
    }

    @Transactional(readOnly = true)
    public List<AcademicLevelResponse> getPublicLevelsForProgram(Long programId) {
        programRepository.findByProgramIdAndDeletedFalse(programId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic program not found with ID: " + programId));

        return levelMapper.toResponseList(levelRepository.findByProgram_ProgramIdAndDeletedFalse(programId));
    }

    @Transactional(readOnly = true)
    public List<AcademicLevelResponse> getAllLevelsForInstitution() {
        Long tenantId = requireTenantId();
        return levelMapper.toResponseList(levelRepository.findActiveByInstitutionId(tenantId));
    }

    @Transactional
    public void deleteLevel(Long levelId) {
        Long tenantId = requireTenantId();
        AcademicLevel level = levelRepository
                .findActiveByIdAndInstitutionId(levelId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic level not found with ID: " + levelId));

        LocalDateTime now = LocalDateTime.now();

        subjectRepository.softDeleteByLevelIds(List.of(levelId), now);
        studentRepository.clearAcademicLevel(levelId);

        level.setDeleted(true);
        level.setDeletedAt(now);
        levelRepository.save(level);
    }

    // ── Subject Management ────────────────────────────────────────────────────

    @Transactional
    public SubjectResponse createSubject(CreateSubjectRequest request) {
        Long tenantId = requireTenantId();
        AcademicLevel level = levelRepository
                .findActiveByIdAndInstitutionId(request.getLevelId(), tenantId)
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
        return subjectMapper.toResponse(saved);
    }

    @Transactional
    public List<SubjectResponse> batchCreateSubjects(BatchCreateSubjectRequest request) {
        Long tenantId = requireTenantId();
        AcademicLevel level = levelRepository
                .findActiveByIdAndInstitutionId(request.getLevelId(), tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic level not found with ID: " + request.getLevelId()));

        Set<String> existingNames = subjectRepository
                .findByAcademicLevel_LevelIdAndDeletedFalse(level.getLevelId())
                .stream()
                .map(s -> s.getName().toLowerCase())
                .collect(Collectors.toSet());

        List<Subject> toCreate = new ArrayList<>();
        for (BatchCreateSubjectRequest.SubjectItem item : request.getSubjects()) {
            String trimmedName = item.getName().trim();
            if (existingNames.contains(trimmedName.toLowerCase())) {
                log.warn("Skipping duplicate subject creation: '{}' for level {}", trimmedName, level.getLevelId());
                continue;
            }
            existingNames.add(trimmedName.toLowerCase());
            toCreate.add(Subject.builder()
                    .academicLevel(level)
                    .name(trimmedName)
                    .code(item.getCode() != null ? item.getCode().trim() : null)
                    .creditHours(item.getCreditHours() != null ? item.getCreditHours() : 3)
                    .build());
        }

        List<Subject> saved = subjectRepository.saveAll(toCreate);
        return subjectMapper.toResponseList(saved);
    }

    @Transactional(readOnly = true)
    public List<SubjectResponse> getSubjectsForLevel(Long levelId) {
        Long tenantId = requireTenantId();
        levelRepository.findActiveByIdAndInstitutionId(levelId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic level not found with ID: " + levelId));

        return subjectMapper.toResponseList(subjectRepository.findByAcademicLevel_LevelIdAndDeletedFalse(levelId));
    }

    @Transactional(readOnly = true)
    public List<SubjectResponse> getAllSubjects() {
        Long tenantId = requireTenantId();
        return subjectMapper.toResponseList(subjectRepository.findActiveByInstitutionId(tenantId));
    }

    @Transactional
    public SubjectResponse updateSubject(Long subjectId, CreateSubjectRequest request) {
        Long tenantId = requireTenantId();
        Subject subject = subjectRepository
                .findActiveByIdAndInstitutionId(subjectId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Subject not found with ID: " + subjectId));

        if (request.getLevelId() != null && !request.getLevelId().equals(subject.getAcademicLevel().getLevelId())) {
            AcademicLevel newLevel = levelRepository
                    .findActiveByIdAndInstitutionId(request.getLevelId(), tenantId)
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
        return subjectMapper.toResponse(saved);
    }

    @Transactional
    public void deleteSubject(Long subjectId) {
        Long tenantId = requireTenantId();
        Subject subject = subjectRepository
                .findActiveByIdAndInstitutionId(subjectId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Subject not found with ID: " + subjectId));

        subject.setDeleted(true);
        subject.setDeletedAt(LocalDateTime.now());
        subjectRepository.save(subject);
    }

    // ── Private Helpers ───────────────────────────────────────────────────────

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
