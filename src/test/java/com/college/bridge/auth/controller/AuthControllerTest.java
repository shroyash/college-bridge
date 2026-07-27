package com.college.bridge.auth.controller;

import com.college.bridge.academic.entity.Faculty;
import com.college.bridge.auth.dto.*;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.security.CustomUserDetailsService;
import com.college.bridge.auth.security.JwtAccessDeniedHandler;
import com.college.bridge.auth.security.JwtAuthenticationEntryPoint;
import com.college.bridge.auth.security.JwtService;
import com.college.bridge.auth.service.AuthService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(AuthController.class)
@AutoConfigureMockMvc(addFilters = false)
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private AuthService authService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService customUserDetailsService;

    @MockBean
    private JwtAuthenticationEntryPoint authenticationEntryPoint;

    @MockBean
    private JwtAccessDeniedHandler accessDeniedHandler;

    @Test
    @DisplayName("POST /api/auth/register - Should register student successfully")
    void testRegisterSuccess() throws Exception {
        RegisterRequest request = RegisterRequest.builder()
                .email("student@college.edu")
                .password("Password123!")
                .name("Jane Student")
                .faculty(Faculty.BCA)
                .semester(1)
                .build();

        AuthResponse authResponse = AuthResponse.builder()
                .accessToken("mock-access-token")
                .refreshToken("mock-refresh-token")
                .name("Jane Student")
                .email("student@college.edu")
                .role("STUDENT")
                .build();

        when(authService.register(any(RegisterRequest.class))).thenReturn(authResponse);

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Student registered successfully."))
                .andExpect(jsonPath("$.data.accessToken").value("mock-access-token"));
    }

    @Test
    @DisplayName("POST /api/auth/login - Should authenticate user and return tokens")
    void testLoginSuccess() throws Exception {
        LoginRequest request = LoginRequest.builder()
                .email("student@college.edu")
                .password("Password123!")
                .build();

        AuthResponse authResponse = AuthResponse.builder()
                .accessToken("mock-access-token")
                .refreshToken("mock-refresh-token")
                .name("Jane Student")
                .email("student@college.edu")
                .role("STUDENT")
                .build();

        when(authService.login(any(LoginRequest.class))).thenReturn(authResponse);

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.accessToken").value("mock-access-token"));
    }

    @Test
    @DisplayName("POST /api/auth/refresh - Should refresh JWT token")
    void testRefreshSuccess() throws Exception {
        TokenRefreshRequest request = new TokenRefreshRequest();
        request.setRefreshToken("valid-refresh-token");

        AuthResponse authResponse = AuthResponse.builder()
                .accessToken("new-access-token")
                .refreshToken("new-refresh-token")
                .name("Jane Student")
                .email("student@college.edu")
                .role("STUDENT")
                .build();

        when(authService.refreshToken(any(TokenRefreshRequest.class))).thenReturn(authResponse);

        mockMvc.perform(post("/api/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.accessToken").value("new-access-token"));
    }

    @Test
    @DisplayName("POST /api/auth/logout - Should revoke token and return success")
    void testLogoutSuccess() throws Exception {
        TokenRefreshRequest request = new TokenRefreshRequest();
        request.setRefreshToken("valid-refresh-token");

        doNothing().when(authService).logout("valid-refresh-token");

        mockMvc.perform(post("/api/auth/logout")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Successfully logged out. Refresh token revoked."));
    }

    @Test
    @DisplayName("POST /api/auth/forgot-password - Should send forgot password OTP")
    void testForgotPasswordSuccess() throws Exception {
        ForgotPasswordRequest request = new ForgotPasswordRequest();
        request.setEmail("student@college.edu");

        doNothing().when(authService).forgotPassword(any(ForgotPasswordRequest.class));

        mockMvc.perform(post("/api/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    @DisplayName("POST /api/auth/verify-otp - Should verify OTP code")
    void testVerifyOtpSuccess() throws Exception {
        VerifyOtpRequest request = new VerifyOtpRequest();
        request.setEmail("student@college.edu");
        request.setCode("123456");
        request.setType(com.college.bridge.auth.entity.OtpType.PASSWORD_RESET);

        OtpVerificationResponse response = OtpVerificationResponse.builder()
                .verified(true)
                .verificationToken("verification-reset-token")
                .build();

        when(authService.verifyOtp(any(VerifyOtpRequest.class))).thenReturn(response);

        mockMvc.perform(post("/api/auth/verify-otp")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.verificationToken").value("verification-reset-token"));
    }
}
