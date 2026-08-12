package com.college.bridge.institution;

import com.college.bridge.auth.dto.LoginRequest;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.entity.UserStatus;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.auth.security.JwtService;
import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.config.EnvLoader;
import com.college.bridge.institution.dto.RegisterInstitutionRequest;
import com.college.bridge.institution.dto.RejectInstitutionRequest;
import com.college.bridge.institution.entity.Institution;
import com.college.bridge.institution.entity.InstitutionDocument;
import com.college.bridge.institution.entity.InstitutionStatus;
import com.college.bridge.institution.repository.InstitutionDocumentRepository;
import com.college.bridge.institution.repository.InstitutionRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
public class InstitutionWorkflowIntegrationTest {

    static {
        EnvLoader.loadEnv();
    }

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private InstitutionRepository institutionRepository;

    @Autowired
    private InstitutionDocumentRepository institutionDocumentRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtService jwtService;

    private User superAdminUser;
    private String superAdminToken;

    @BeforeEach
    void setUp() {
        superAdminUser = userRepository.save(User.builder()
                .name("Super Admin")
                .email("superadmin_" + UUID.randomUUID().toString().substring(0, 6) + "@test.com")
                .passwordHash(passwordEncoder.encode("SuperSecret123"))
                .role(UserRole.SUPER_ADMIN)
                .status(UserStatus.ACTIVE)
                .build());

        superAdminToken = jwtService.generateAccessToken(new UserPrincipal(superAdminUser));
    }

    @Test
    @DisplayName("1. Self-serve registration creates Institution and Admin User in PENDING state and returns NO JWT")
    void testRegistration_createsPendingInstitutionAndUser_returnsNoJwt() throws Exception {
        String instCode = "INST_" + UUID.randomUUID().toString().substring(0, 6);
        RegisterInstitutionRequest req = RegisterInstitutionRequest.builder()
                .name("Test University")
                .code(instCode)
                .adminName("Admin One")
                .adminEmail("admin1@" + instCode.toLowerCase() + ".edu")
                .adminPassword("Password123!")
                .documentTypes(List.of("TRADE_LICENSE"))
                .build();

        MockMultipartFile requestPart = new MockMultipartFile(
                "request",
                "",
                MediaType.APPLICATION_JSON_VALUE,
                objectMapper.writeValueAsBytes(req)
        );

        MockMultipartFile filePart = new MockMultipartFile(
                "documents",
                "trade_license.pdf",
                MediaType.APPLICATION_PDF_VALUE,
                "Sample Trade License Content".getBytes()
        );

        mockMvc.perform(multipart("/api/auth/register-institution")
                        .file(requestPart)
                        .file(filePart))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("PENDING"))
                .andExpect(jsonPath("$.data.code").value(instCode))
                .andExpect(jsonPath("$.data.accessToken").doesNotExist());

        // Verify Database State
        Institution inst = institutionRepository.findByCode(instCode).orElseThrow();
        assertEquals(InstitutionStatus.PENDING, inst.getStatus());

        User admin = userRepository.findByInstitution_InstitutionIdAndEmail(inst.getInstitutionId(), "admin1@" + instCode.toLowerCase() + ".edu").orElseThrow();
        assertEquals(UserStatus.PENDING_VERIFICATION, admin.getStatus());
        assertEquals(UserRole.ADMIN, admin.getRole());
        assertEquals(admin.getUserId(), inst.getSubmittedBy().getUserId());

        List<InstitutionDocument> docs = institutionDocumentRepository.findByInstitution_InstitutionId(inst.getInstitutionId());
        assertEquals(1, docs.size());
        assertEquals("TRADE_LICENSE", docs.get(0).getDocumentType());
    }

    @Test
    @DisplayName("2. Login is blocked for PENDING institution even with valid password")
    void testLogin_blockedForPendingInstitution() throws Exception {
        Institution inst = institutionRepository.save(Institution.builder()
                .name("Pending Tech")
                .code("PEND_" + UUID.randomUUID().toString().substring(0, 5))
                .status(InstitutionStatus.PENDING)
                .build());

        User admin = userRepository.save(User.builder()
                .institution(inst)
                .name("Pending Admin")
                .email("admin@pending.edu")
                .passwordHash(passwordEncoder.encode("ValidPass123!"))
                .role(UserRole.ADMIN)
                .status(UserStatus.PENDING_VERIFICATION)
                .build());

        LoginRequest loginReq = LoginRequest.builder()
                .institutionCode(inst.getCode())
                .email(admin.getEmail())
                .password("ValidPass123!")
                .build();

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginReq)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("Institution registration is awaiting approval."));
    }

    @Test
    @DisplayName("3. Approval flips both Institution and Admin User to ACTIVE and login then succeeds")
    void testApprove_flipsInstitutionAndUserToActive_loginSucceeds() throws Exception {
        Institution inst = institutionRepository.save(Institution.builder()
                .name("Approve Institute")
                .code("APP_" + UUID.randomUUID().toString().substring(0, 5))
                .status(InstitutionStatus.PENDING)
                .build());

        User admin = userRepository.save(User.builder()
                .institution(inst)
                .name("Approve Admin")
                .email("admin@approve.edu")
                .passwordHash(passwordEncoder.encode("ValidPass123!"))
                .role(UserRole.ADMIN)
                .status(UserStatus.PENDING_VERIFICATION)
                .build());

        inst.setSubmittedBy(admin);
        institutionRepository.save(inst);

        // Super admin approves institution
        mockMvc.perform(post("/api/super-admin/institutions/{id}/approve", inst.getInstitutionId())
                        .header("Authorization", "Bearer " + superAdminToken)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Institution and admin user approved successfully."));

        // Verify DB
        Institution updatedInst = institutionRepository.findById(inst.getInstitutionId()).orElseThrow();
        assertEquals(InstitutionStatus.ACTIVE, updatedInst.getStatus());

        User updatedAdmin = userRepository.findById(admin.getUserId()).orElseThrow();
        assertEquals(UserStatus.ACTIVE, updatedAdmin.getStatus());

        // Login should now succeed
        LoginRequest loginReq = LoginRequest.builder()
                .institutionCode(inst.getCode())
                .email(admin.getEmail())
                .password("ValidPass123!")
                .build();

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.accessToken").exists());
    }

    @Test
    @DisplayName("4. Rejection blocks login and surfaces rejection reason")
    void testReject_blocksLoginAndSurfacesRejectionReason() throws Exception {
        Institution inst = institutionRepository.save(Institution.builder()
                .name("Reject Academy")
                .code("REJ_" + UUID.randomUUID().toString().substring(0, 5))
                .status(InstitutionStatus.PENDING)
                .build());

        User admin = userRepository.save(User.builder()
                .institution(inst)
                .name("Reject Admin")
                .email("admin@reject.edu")
                .passwordHash(passwordEncoder.encode("ValidPass123!"))
                .role(UserRole.ADMIN)
                .status(UserStatus.PENDING_VERIFICATION)
                .build());

        RejectInstitutionRequest rejectReq = RejectInstitutionRequest.builder()
                .rejectionReason("Invalid trade license document provided.")
                .build();

        mockMvc.perform(post("/api/super-admin/institutions/{id}/reject", inst.getInstitutionId())
                        .header("Authorization", "Bearer " + superAdminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(rejectReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Institution registration rejected successfully."));

        // Verify DB
        Institution updatedInst = institutionRepository.findById(inst.getInstitutionId()).orElseThrow();
        assertEquals(InstitutionStatus.REJECTED, updatedInst.getStatus());
        assertEquals("Invalid trade license document provided.", updatedInst.getRejectionReason());

        // Attempt login -> Expect 403 with rejection reason
        LoginRequest loginReq = LoginRequest.builder()
                .institutionCode(inst.getCode())
                .email(admin.getEmail())
                .password("ValidPass123!")
                .build();

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginReq)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Institution registration was rejected. Reason: Invalid trade license document provided."));
    }

    @Test
    @DisplayName("5. Suspended institution blocks individually ACTIVE user login")
    void testSuspendedInstitution_blocksIndividuallyActiveUserLogin() throws Exception {
        Institution inst = institutionRepository.save(Institution.builder()
                .name("Active Inst")
                .code("ACT_" + UUID.randomUUID().toString().substring(0, 5))
                .status(InstitutionStatus.ACTIVE)
                .build());

        User user = userRepository.save(User.builder()
                .institution(inst)
                .name("Active User")
                .email("user@active.edu")
                .passwordHash(passwordEncoder.encode("ValidPass123!"))
                .role(UserRole.STUDENT)
                .status(UserStatus.ACTIVE)
                .build());

        // Super Admin suspends the institution
        mockMvc.perform(post("/api/super-admin/institutions/{id}/suspend", inst.getInstitutionId())
                        .header("Authorization", "Bearer " + superAdminToken)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk());

        // Verify DB: Institution is SUSPENDED, user is still ACTIVE
        Institution updatedInst = institutionRepository.findById(inst.getInstitutionId()).orElseThrow();
        assertEquals(InstitutionStatus.SUSPENDED, updatedInst.getStatus());

        User updatedUser = userRepository.findById(user.getUserId()).orElseThrow();
        assertEquals(UserStatus.ACTIVE, updatedUser.getStatus());

        // Login attempt fails with institution suspended message
        LoginRequest loginReq = LoginRequest.builder()
                .institutionCode(inst.getCode())
                .email(user.getEmail())
                .password("ValidPass123!")
                .build();

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginReq)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Institution is suspended. Please contact support."));
    }

    @Test
    @DisplayName("6. Individually SUSPENDED user at ACTIVE institution blocked with distinct message")
    void testIndividuallySuspendedUserAtActiveInstitution_blockedWithDistinctMessage() throws Exception {
        Institution inst = institutionRepository.save(Institution.builder()
                .name("Active Inst 2")
                .code("ACT2_" + UUID.randomUUID().toString().substring(0, 4))
                .status(InstitutionStatus.ACTIVE)
                .build());

        User user = userRepository.save(User.builder()
                .institution(inst)
                .name("Suspended User")
                .email("suspended@active.edu")
                .passwordHash(passwordEncoder.encode("ValidPass123!"))
                .role(UserRole.STUDENT)
                .status(UserStatus.SUSPENDED)
                .build());

        LoginRequest loginReq = LoginRequest.builder()
                .institutionCode(inst.getCode())
                .email(user.getEmail())
                .password("ValidPass123!")
                .build();

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginReq)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("User account is suspended."));
    }

    @Test
    @DisplayName("7. SUPER_ADMIN skips institution checks during login")
    void testSuperAdminLogin_bypassesInstitutionCheck() throws Exception {
        LoginRequest loginReq = LoginRequest.builder()
                .email(superAdminUser.getEmail())
                .password("SuperSecret123")
                .build();

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.accessToken").exists())
                .andExpect(jsonPath("$.data.role").value("SUPER_ADMIN"));
    }
}
