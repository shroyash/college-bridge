package com.college.bridge.verification.controller;

import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.entity.UserStatus;
import com.college.bridge.auth.security.CustomUserDetails;
import com.college.bridge.auth.security.CustomUserDetailsService;
import com.college.bridge.auth.security.JwtAccessDeniedHandler;
import com.college.bridge.auth.security.JwtAuthenticationEntryPoint;
import com.college.bridge.auth.security.JwtService;
import com.college.bridge.verification.dto.ReviewDecisionRequest;
import com.college.bridge.verification.dto.SubmitVerificationRequest;
import com.college.bridge.verification.dto.VerificationStatusResponse;
import com.college.bridge.verification.entity.VerificationStatus;
import com.college.bridge.verification.service.TeacherVerificationService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(TeacherVerificationController.class)
@AutoConfigureMockMvc(addFilters = false)
class TeacherVerificationControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private TeacherVerificationService verificationService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService customUserDetailsService;

    @MockBean
    private com.college.bridge.auth.service.UserTokenRevocationService userTokenRevocationService;

    @MockBean
    private JwtAuthenticationEntryPoint authenticationEntryPoint;

    @MockBean
    private JwtAccessDeniedHandler accessDeniedHandler;

    private User studentUser;
    private User adminUser;

    @BeforeEach
    void setUp() {
        studentUser = User.builder()
                .userId(10L)
                .email("student@college.edu")
                .role(UserRole.STUDENT)
                .status(UserStatus.ACTIVE)
                .build();

        adminUser = User.builder()
                .userId(1L)
                .email("admin@college.edu")
                .role(UserRole.ADMIN)
                .status(UserStatus.ACTIVE)
                .build();
    }

    private void setSecurityUser(User user) {
        CustomUserDetails userDetails = new CustomUserDetails(user);
        UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                userDetails, null, userDetails.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    @DisplayName("POST /api/verification/submit - Should submit verification request")
    void testSubmitRequestSuccess() throws Exception {
        setSecurityUser(studentUser);

        SubmitVerificationRequest request = new SubmitVerificationRequest();
        request.setDocumentUrls(List.of("https://storage/doc.pdf"));

        VerificationStatusResponse response = VerificationStatusResponse.builder()
                .requestId(100L)
                .status(VerificationStatus.PENDING)
                .documentUrls(List.of("https://storage/doc.pdf"))
                .build();

        when(verificationService.submitRequest(eq(10L), any(SubmitVerificationRequest.class)))
                .thenReturn(response);

        mockMvc.perform(post("/api/verification/submit")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.requestId").value(100));
    }

    @Test
    @DisplayName("GET /api/verification/my-request - Should get user verification request")
    void testGetMyRequestSuccess() throws Exception {
        setSecurityUser(studentUser);

        VerificationStatusResponse response = VerificationStatusResponse.builder()
                .requestId(100L)
                .status(VerificationStatus.PENDING)
                .documentUrls(List.of("https://storage/doc.pdf"))
                .build();

        when(verificationService.getMyRequest(10L)).thenReturn(response);

        mockMvc.perform(get("/api/verification/my-request"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.requestId").value(100));
    }

    @Test
    @DisplayName("GET /api/admin/verification/pending - Should return pending requests")
    void testGetPendingRequestsSuccess() throws Exception {
        VerificationStatusResponse response = VerificationStatusResponse.builder()
                .requestId(100L)
                .status(VerificationStatus.PENDING)
                .documentUrls(List.of("https://storage/doc.pdf"))
                .build();

        when(verificationService.getPendingRequests()).thenReturn(List.of(response));

        mockMvc.perform(get("/api/admin/verification/pending"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].requestId").value(100));
    }

    @Test
    @DisplayName("POST /api/admin/verification/{requestId}/approve - Should approve request")
    void testApproveRequestSuccess() throws Exception {
        setSecurityUser(adminUser);

        VerificationStatusResponse response = VerificationStatusResponse.builder()
                .requestId(100L)
                .status(VerificationStatus.APPROVED)
                .documentUrls(List.of("https://storage/doc.pdf"))
                .build();

        when(verificationService.approveRequest(1L, 100L)).thenReturn(response);

        mockMvc.perform(post("/api/admin/verification/100/approve"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("APPROVED"));
    }

    @Test
    @DisplayName("POST /api/admin/verification/{requestId}/reject - Should reject request")
    void testRejectRequestSuccess() throws Exception {
        setSecurityUser(adminUser);

        ReviewDecisionRequest decision = new ReviewDecisionRequest();
        decision.setRejectionReason("Documents unclear");

        VerificationStatusResponse response = VerificationStatusResponse.builder()
                .requestId(100L)
                .status(VerificationStatus.REJECTED)
                .rejectionReason("Documents unclear")
                .build();

        when(verificationService.rejectRequest(eq(1L), eq(100L), any(ReviewDecisionRequest.class)))
                .thenReturn(response);

        mockMvc.perform(post("/api/admin/verification/100/reject")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(decision)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("REJECTED"));
    }
}
