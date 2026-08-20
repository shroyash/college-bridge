package com.college.bridge.academic;

import com.college.bridge.academic.dto.AcademicClassResponse;
import com.college.bridge.academic.dto.CreateAcademicClassRequest;
import com.college.bridge.academic.dto.CreateSubjectRequest;
import com.college.bridge.academic.dto.SubjectResponse;
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
                .name("Dynamic Faculty College")
                .code("DFC_" + UUID.randomUUID().toString().substring(0, 6))
                .status(InstitutionStatus.ACTIVE)
                .build());

        TenantContext.set(institution.getInstitutionId());
    }

    @Test
    @DisplayName("Should create custom faculties BIT, BE_CIVIL, BSW and retrieve them in institution faculties list")
    void testCreateCustomFaculties() {
        // Create BIT
        AcademicClassResponse bitClass = academicAdminService.createAcademicClass(CreateAcademicClassRequest.builder()
                .faculty("BIT")
                .semester(1)
                .build());
        assertEquals("BIT", bitClass.getFaculty());
        assertEquals("BIT First Semester", bitClass.getDisplayName());

        // Create BE_CIVIL
        AcademicClassResponse civilClass = academicAdminService.createAcademicClass(CreateAcademicClassRequest.builder()
                .faculty("BE_CIVIL")
                .semester(1)
                .build());
        assertEquals("BE_CIVIL", civilClass.getFaculty());

        // Create BSW Subject (which auto-creates BSW Sem 1 AcademicClass)
        SubjectResponse bswSubject = academicAdminService.createSubject(CreateSubjectRequest.builder()
                .name("Social Work Fundamentals")
                .faculty("BSW")
                .semester(1)
                .creditHours(3)
                .build());
        assertEquals("BSW", bswSubject.getFaculty());

        // Retrieve distinct faculties
        List<String> faculties = academicAdminService.getInstitutionFaculties();
        assertTrue(faculties.contains("BIT"));
        assertTrue(faculties.contains("BE_CIVIL"));
        assertTrue(faculties.contains("BSW"));
    }
}
