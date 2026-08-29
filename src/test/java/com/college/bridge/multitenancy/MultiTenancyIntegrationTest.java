package com.college.bridge.multitenancy;

import com.college.bridge.academic.entity.AcademicLevel;
import com.college.bridge.academic.entity.AcademicLevelType;
import com.college.bridge.academic.entity.AcademicProgram;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.repository.AcademicLevelRepository;
import com.college.bridge.academic.repository.AcademicProgramRepository;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.auth.security.JwtService;
import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.config.EnvLoader;
import com.college.bridge.institution.entity.Institution;
import com.college.bridge.institution.entity.InstitutionStatus;
import com.college.bridge.institution.repository.InstitutionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
public class MultiTenancyIntegrationTest {

    static {
        EnvLoader.loadEnv();
    }

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private InstitutionRepository institutionRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AcademicProgramRepository programRepository;

    @Autowired
    private AcademicLevelRepository levelRepository;

    @Autowired
    private SubjectRepository subjectRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtService jwtService;

    private Institution instA;
    private Institution instB;
    private User adminA;
    private User adminB;
    private String tokenAdminA;
    private String tokenAdminB;
    private AcademicProgram programA;
    private AcademicProgram programB;
    private AcademicLevel levelA;
    private AcademicLevel levelB;
    private Subject subjectA;
    private Subject subjectB;

    @BeforeEach
    void setUp() {
        // Create 2 Institutions
        instA = institutionRepository.save(Institution.builder()
                .name("Institution A")
                .code("INST_A_" + UUID.randomUUID().toString().substring(0, 6))
                .status(InstitutionStatus.ACTIVE)
                .build());

        instB = institutionRepository.save(Institution.builder()
                .name("Institution B")
                .code("INST_B_" + UUID.randomUUID().toString().substring(0, 6))
                .status(InstitutionStatus.ACTIVE)
                .build());

        // Create 2 Admins
        adminA = userRepository.save(User.builder()
                .institution(instA)
                .name("Admin A")
                .email("adminA_" + UUID.randomUUID().toString().substring(0, 6) + "@test.com")
                .passwordHash(passwordEncoder.encode("Password123"))
                .role(UserRole.ADMIN)
                .build());

        adminB = userRepository.save(User.builder()
                .institution(instB)
                .name("Admin B")
                .email("adminB_" + UUID.randomUUID().toString().substring(0, 6) + "@test.com")
                .passwordHash(passwordEncoder.encode("Password123"))
                .role(UserRole.ADMIN)
                .build());

        tokenAdminA = jwtService.generateAccessToken(new UserPrincipal(adminA));
        tokenAdminB = jwtService.generateAccessToken(new UserPrincipal(adminB));

        // Create Programs
        programA = programRepository.save(AcademicProgram.builder()
                .institution(instA)
                .name("BCA Inst A")
                .code("BCA_A")
                .build());

        programB = programRepository.save(AcademicProgram.builder()
                .institution(instB)
                .name("BCA Inst B")
                .code("BCA_B")
                .build());

        // Create Levels
        levelA = levelRepository.save(AcademicLevel.builder()
                .program(programA)
                .name("1st Semester")
                .levelNumber(1)
                .type(AcademicLevelType.SEMESTER)
                .build());

        levelB = levelRepository.save(AcademicLevel.builder()
                .program(programB)
                .name("1st Semester")
                .levelNumber(1)
                .type(AcademicLevelType.SEMESTER)
                .build());

        // Create Subjects
        subjectA = subjectRepository.save(Subject.builder()
                .academicLevel(levelA)
                .name("Physics Inst A")
                .code("PHY101")
                .creditHours(3)
                .build());

        subjectB = subjectRepository.save(Subject.builder()
                .academicLevel(levelB)
                .name("Chemistry Inst B")
                .code("CHE101")
                .creditHours(3)
                .build());
    }

    @Test
    @DisplayName("Admin A can fetch Subject A by ID, but gets 404 when fetching Subject B by ID")
    void testSubjectByIdTenantIsolation() throws Exception {
        // Fetch own subject -> 200 OK
        mockMvc.perform(get("/api/academic/subjects/{id}", subjectA.getSubjectId())
                        .header("Authorization", "Bearer " + tokenAdminA)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Physics Inst A"));

        // Fetch cross-tenant subject -> 404 NOT FOUND
        mockMvc.perform(get("/api/academic/subjects/{id}", subjectB.getSubjectId())
                        .header("Authorization", "Bearer " + tokenAdminA)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound());
    }

    @Test
    @DisplayName("List endpoints return only records belonging to Admin A's institution")
    void testListEndpointsTenantIsolation() throws Exception {
        // List subjects for Admin A
        mockMvc.perform(get("/api/academic/subjects/all")
                        .header("Authorization", "Bearer " + tokenAdminA)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[*].name", hasItem("Physics Inst A")))
                .andExpect(jsonPath("$[*].name", not(hasItem("Chemistry Inst B"))));

        // List programs for Admin A
        mockMvc.perform(get("/api/admin/academic/programs")
                        .header("Authorization", "Bearer " + tokenAdminA)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[*].code", hasItem("BCA_A")))
                .andExpect(jsonPath("$.data[*].code", not(hasItem("BCA_B"))));
    }
}
