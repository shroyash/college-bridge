package com.college.bridge.auth.controller;

import com.college.bridge.auth.dto.ChangeRoleRequest;
import com.college.bridge.auth.dto.RejectTeacherRequest;
import com.college.bridge.auth.dto.UserProfileResponse;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.entity.UserStatus;
import com.college.bridge.auth.security.CustomUserDetailsService;
import com.college.bridge.auth.security.JwtAccessDeniedHandler;
import com.college.bridge.auth.security.JwtAuthenticationEntryPoint;
import com.college.bridge.auth.security.JwtService;
import com.college.bridge.auth.service.AdminUserService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(AdminUserController.class)
@AutoConfigureMockMvc(addFilters = false)
class AdminUserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private AdminUserService adminUserService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService customUserDetailsService;

    @MockBean
    private JwtAuthenticationEntryPoint authenticationEntryPoint;

    @MockBean
    private JwtAccessDeniedHandler accessDeniedHandler;

    @Test
    @WithMockUser(username = "admin@college.edu", roles = {"ADMIN"})
    @DisplayName("GET /api/admin/users - Should return paged users")
    void testGetAllUsersSuccess() throws Exception {
        UserProfileResponse profile = UserProfileResponse.builder()
                .userId(1L)
                .email("user@college.edu")
                .name("Test User")
                .role(UserRole.STUDENT.name())
                .build();

        when(adminUserService.getAllUsers(any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(profile)));

        mockMvc.perform(get("/api/admin/users"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content[0].email").value("user@college.edu"));
    }

    @Test
    @WithMockUser(username = "admin@college.edu", roles = {"ADMIN"})
    @DisplayName("POST /api/admin/teacher/{id}/verify - Should verify teacher")
    void testVerifyTeacherSuccess() throws Exception {
        doNothing().when(adminUserService).verifyTeacher(1L, "admin@college.edu");

        mockMvc.perform(post("/api/admin/teacher/1/verify"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Teacher verified."));
    }

    @Test
    @WithMockUser(username = "admin@college.edu", roles = {"ADMIN"})
    @DisplayName("POST /api/admin/teacher/{id}/reject - Should reject teacher verification")
    void testRejectTeacherSuccess() throws Exception {
        RejectTeacherRequest request = new RejectTeacherRequest();
        request.setRejectionReason("Incomplete documents");

        doNothing().when(adminUserService).rejectTeacher(eq(1L), any(RejectTeacherRequest.class), eq("admin@college.edu"));

        mockMvc.perform(post("/api/admin/teacher/1/reject")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Teacher rejected."));
    }

    @Test
    @WithMockUser(username = "admin@college.edu", roles = {"ADMIN"})
    @DisplayName("POST /api/admin/users/{id}/suspend - Should suspend user")
    void testSuspendUserSuccess() throws Exception {
        doNothing().when(adminUserService).suspendUser(2L);

        mockMvc.perform(post("/api/admin/users/2/suspend"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("User suspended."));
    }

    @Test
    @WithMockUser(username = "admin@college.edu", roles = {"ADMIN"})
    @DisplayName("POST /api/admin/users/{id}/activate - Should activate user")
    void testActivateUserSuccess() throws Exception {
        doNothing().when(adminUserService).activateUser(2L);

        mockMvc.perform(post("/api/admin/users/2/activate"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("User activated."));
    }

    @Test
    @WithMockUser(username = "admin@college.edu", roles = {"ADMIN"})
    @DisplayName("DELETE /api/admin/users/{id} - Should delete user")
    void testDeleteUserSuccess() throws Exception {
        doNothing().when(adminUserService).deleteUser(2L);

        mockMvc.perform(delete("/api/admin/users/2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("User deleted."));
    }
}
