package com.college.bridge.multitenancy;

import com.college.bridge.academic.entity.AcademicClass;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.repository.AcademicClassRepository;
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
    private SubjectRepository subjectRepository;

    @Autowired
    private AcademicClassRepository academicClassRepository;

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
    private Subject subjectA;
    private Subject subjectB;
    private AcademicClass classA;
    private AcademicClass classB;

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

        // Tokens
        tokenAdminA = jwtService.generateAccessToken(new UserPrincipal(adminA));
        tokenAdminB = jwtService.generateAccessToken(new UserPrincipal(adminB));

        // Create Subjects
        subjectA = subjectRepository.save(Subject.builder()
                .institution(instA)
                .name("Physics Inst A")
                .faculty("BCA")
                .semester(1)
                .creditHours(3)
                .build());

        subjectB = subjectRepository.save(Subject.builder()
                .institution(instB)
                .name("Chemistry Inst B")
                .faculty("BCA")
                .semester(1)
                .creditHours(3)
                .build());

        // Create Classes
        classA = academicClassRepository.save(AcademicClass.builder()
                .institution(instA)
                .displayName("BCA 1st Semester Inst A")
                .faculty("BCA")
                .semester(1)
                .build());

        classB = academicClassRepository.save(AcademicClass.builder()
                .institution(instB)
                .displayName("BCA 1st Semester Inst B")
                .faculty("BCA")
                .semester(1)
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
    @DisplayName("Admin A can fetch Class A by ID, but gets 404 when fetching Class B by ID")
    void testClassByIdTenantIsolation() throws Exception {
        // Fetch own class -> 200 OK
        mockMvc.perform(get("/api/admin/academic/classes/{id}/details", classA.getClassId())
                        .header("Authorization", "Bearer " + tokenAdminA)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.displayName").value("BCA 1st Semester Inst A"));

        // Fetch cross-tenant class -> 404 NOT FOUND
        mockMvc.perform(get("/api/admin/academic/classes/{id}/details", classB.getClassId())
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

        // List classes for Admin A
        mockMvc.perform(get("/api/admin/academic/classes")
                        .header("Authorization", "Bearer " + tokenAdminA)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[*].displayName", hasItem("BCA 1st Semester Inst A")))
                .andExpect(jsonPath("$.data[*].displayName", not(hasItem("BCA 1st Semester Inst B"))));
    }
}
