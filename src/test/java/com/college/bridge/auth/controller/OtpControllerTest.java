package com.college.bridge.auth.controller;

import com.college.bridge.auth.entity.OtpType;
import com.college.bridge.auth.security.CustomUserDetailsService;
import com.college.bridge.auth.security.JwtAccessDeniedHandler;
import com.college.bridge.auth.security.JwtAuthenticationEntryPoint;
import com.college.bridge.auth.security.JwtService;
import com.college.bridge.auth.service.OtpService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(OtpController.class)
@AutoConfigureMockMvc(addFilters = false)
class OtpControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private OtpService otpService;

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

    @Test
    @DisplayName("POST /api/otp/send - Should send OTP code")
    void testSendOtpSuccess() throws Exception {
        Map<String, String> body = Map.of(
                "email", "user@college.edu",
                "type", "PASSWORD_RESET"
        );

        doNothing().when(otpService).sendOtp("user@college.edu", OtpType.PASSWORD_RESET);

        mockMvc.perform(post("/api/otp/send")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("OTP sent."));
    }

    @Test
    @DisplayName("POST /api/otp/verify - Should verify OTP code and return token")
    void testVerifyOtpSuccess() throws Exception {
        Map<String, String> body = Map.of(
                "email", "user@college.edu",
                "code", "123456",
                "type", "PASSWORD_RESET"
        );

        when(otpService.verifyOtp("user@college.edu", "123456", OtpType.PASSWORD_RESET))
                .thenReturn("otp-verified-token");

        mockMvc.perform(post("/api/otp/verify")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").value("otp-verified-token"));
    }

    @Test
    @DisplayName("POST /api/otp/validate - Should validate verification token")
    void testValidateOtpSuccess() throws Exception {
        Map<String, String> body = Map.of(
                "email", "user@college.edu",
                "token", "otp-verified-token",
                "type", "PASSWORD_RESET"
        );

        when(otpService.validateVerificationToken("user@college.edu", "otp-verified-token", OtpType.PASSWORD_RESET))
                .thenReturn(true);

        mockMvc.perform(post("/api/otp/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").value(true));
    }
}
