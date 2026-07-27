package com.college.bridge.auth.controller;

import com.college.bridge.auth.dto.*;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.security.CustomUserDetailsService;
import com.college.bridge.auth.security.JwtAccessDeniedHandler;
import com.college.bridge.auth.security.JwtAuthenticationEntryPoint;
import com.college.bridge.auth.security.JwtService;
import com.college.bridge.auth.service.AccountService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(AccountController.class)
@AutoConfigureMockMvc(addFilters = false)
class AccountControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private AccountService accountService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService customUserDetailsService;

    @MockBean
    private JwtAuthenticationEntryPoint authenticationEntryPoint;

    @MockBean
    private JwtAccessDeniedHandler accessDeniedHandler;

    @Test
    @WithMockUser(username = "student@college.edu")
    @DisplayName("GET /api/account/profile - Should return current user profile")
    void testGetProfileSuccess() throws Exception {
        UserProfileResponse response = UserProfileResponse.builder()
                .userId(1L)
                .email("student@college.edu")
                .name("Jane Student")
                .role(UserRole.STUDENT.name())
                .build();

        when(accountService.getProfile("student@college.edu")).thenReturn(response);

        mockMvc.perform(get("/api/account/profile"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.email").value("student@college.edu"));
    }

    @Test
    @WithMockUser(username = "student@college.edu")
    @DisplayName("PUT /api/account/profile - Should update profile")
    void testUpdateProfileSuccess() throws Exception {
        UpdateProfileRequest request = new UpdateProfileRequest();
        request.setName("Jane Updated");

        UserProfileResponse response = UserProfileResponse.builder()
                .userId(1L)
                .email("student@college.edu")
                .name("Jane Updated")
                .role(UserRole.STUDENT.name())
                .build();

        when(accountService.updateProfile(eq("student@college.edu"), any(UpdateProfileRequest.class)))
                .thenReturn(response);

        mockMvc.perform(put("/api/account/profile")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.name").value("Jane Updated"));
    }

    @Test
    @WithMockUser(username = "student@college.edu")
    @DisplayName("POST /api/account/password/change - Should change password")
    void testChangePasswordSuccess() throws Exception {
        ChangePasswordRequest request = new ChangePasswordRequest();
        request.setCurrentPassword("OldPass123!");
        request.setNewPassword("NewPass123!");

        doNothing().when(accountService).changePassword(eq("student@college.edu"), any(ChangePasswordRequest.class));

        mockMvc.perform(post("/api/account/password/change")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    @WithMockUser(username = "student@college.edu")
    @DisplayName("POST /api/account/profile/image - Should upload profile image")
    void testUploadProfileImageSuccess() throws Exception {
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "profile.jpg",
                MediaType.IMAGE_JPEG_VALUE,
                "dummy image content".getBytes()
        );

        when(accountService.uploadProfileImage(eq("student@college.edu"), any())).thenReturn("https://storage/profile.jpg");

        mockMvc.perform(multipart("/api/account/profile/image").file(file))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").value("https://storage/profile.jpg"));
    }

    @Test
    @WithMockUser(username = "student@college.edu")
    @DisplayName("DELETE /api/account - Should delete own account with password")
    void testDeleteAccountSuccess() throws Exception {
        Map<String, String> body = Map.of("password", "Pass123!");

        doNothing().when(accountService).deleteOwnAccount("student@college.edu", "Pass123!");

        mockMvc.perform(delete("/api/account")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }
}
