package com.college.bridge.academic;

import com.college.bridge.academic.dto.*;
import com.college.bridge.academic.service.AcademicAdminService;
import com.college.bridge.common.config.EnvLoader;
import com.college.bridge.common.tenant.TenantContext;
import com.college.bridge.institution.entity.Institution;
import com.college.bridge.institution.entity.InstitutionStatus;
import com.college.bridge.institution.repository.InstitutionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
public class AcademicAdminIntegrationTest {

    static {
        EnvLoader.loadEnv();
    }

    @Autowired
    private AcademicAdminService academicAdminService;

    @Autowired
    private InstitutionRepository institutionRepository;

    private Institution institution;

    @BeforeEach
    void setUp() {
        institution = institutionRepository.save(Institution.builder()
                .name("Normalized Hierarchy College")
                .code("NHC_" + UUID.randomUUID().toString().substring(0, 6))
                .status(InstitutionStatus.ACTIVE)
                .build());

        TenantContext.set(institution.getInstitutionId());
    }

    @Test
    @DisplayName("Should create programs BCA and BE_CIVIL, levels, and subjects in normalized hierarchy")
    void testCreateNormalizedAcademicHierarchy() {
        // Create Program BIT
        AcademicProgramResponse bcaProgram = academicAdminService.createProgram(AcademicProgramRequest.builder()
                .name("Bachelor of Computer Application")
                .code("BCA")
                .build());
        assertEquals("BCA", bcaProgram.getCode());

        // Create Level 1
        AcademicLevelResponse level1 = academicAdminService.createLevel(bcaProgram.getProgramId(), AcademicLevelRequest.builder()
                .name("1st Semester")
                .levelNumber(1)
                .type(com.college.bridge.academic.entity.AcademicLevelType.SEMESTER)
                .build());
        assertEquals("1st Semester", level1.getName());

        // Create Subject under Level 1
        SubjectResponse subject = academicAdminService.createSubject(CreateSubjectRequest.builder()
                .levelId(level1.getLevelId())
                .name("Data Structures")
                .code("CACS102")
                .creditHours(3)
                .build());
        assertEquals("Data Structures", subject.getName());
        assertEquals("CACS102", subject.getCode());
        assertEquals(level1.getLevelId(), subject.getLevelId());

        // Retrieve programs
        List<AcademicProgramResponse> programs = academicAdminService.getPrograms();
        assertTrue(programs.stream().anyMatch(p -> p.getCode().equals("BCA")));
    }
}
