package com.college.bridge.clazz.controller;

import com.college.bridge.academic.entity.Faculty;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.entity.UserStatus;
import com.college.bridge.auth.security.CustomUserDetails;
import com.college.bridge.auth.security.CustomUserDetailsService;
import com.college.bridge.auth.security.JwtAccessDeniedHandler;
import com.college.bridge.auth.security.JwtAuthenticationEntryPoint;
import com.college.bridge.auth.security.JwtService;
import com.college.bridge.clazz.dto.AssignTeacherRequest;
import com.college.bridge.clazz.dto.ClassResponse;
import com.college.bridge.clazz.dto.CreateClassRequest;
import com.college.bridge.clazz.service.ClassService;
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

@WebMvcTest(ClassController.class)
@AutoConfigureMockMvc(addFilters = false)
class ClassControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private ClassService classService;

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

    @BeforeEach
    void setUp() {
        studentUser = User.builder()
                .userId(10L)
                .email("student@college.edu")
                .role(UserRole.STUDENT)
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
    @DisplayName("POST /api/admin/classes - Should create a class")
    void testCreateClassSuccess() throws Exception {
        CreateClassRequest request = CreateClassRequest.builder()
                .faculty(Faculty.BCA)
                .semester(1)
                .build();

        ClassResponse response = ClassResponse.builder()
                .classId(1L)
                .className("BCA 1st Semester")
                .faculty(Faculty.BCA)
                .semester(1)
                .build();

        when(classService.createClass(any(CreateClassRequest.class))).thenReturn(response);

        mockMvc.perform(post("/api/admin/classes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.className").value("BCA 1st Semester"));
    }

    @Test
    @DisplayName("POST /api/admin/classes/{classId}/assign-teacher - Should assign teacher to class")
    void testAssignTeacherSuccess() throws Exception {
        AssignTeacherRequest request = AssignTeacherRequest.builder()
                .teacherId(5L)
                .build();

        ClassResponse response = ClassResponse.builder()
                .classId(1L)
                .className("BCA 1st Semester")
                .teacherName("Dr. Teacher")
                .build();

        when(classService.assignTeacher(eq(1L), any(AssignTeacherRequest.class))).thenReturn(response);

        mockMvc.perform(post("/api/admin/classes/1/assign-teacher")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.teacherName").value("Dr. Teacher"));
    }

    @Test
    @DisplayName("GET /api/admin/classes - Should return all classes")
    void testGetAllClassesSuccess() throws Exception {
        ClassResponse response = ClassResponse.builder()
                .classId(1L)
                .className("BCA 1st Semester")
                .build();

        when(classService.getAllClasses()).thenReturn(List.of(response));

        mockMvc.perform(get("/api/admin/classes"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].classId").value(1));
    }

    @Test
    @DisplayName("GET /api/classes/my-classes - Should return user's enrolled or assigned classes")
    void testGetMyClassesSuccess() throws Exception {
        setSecurityUser(studentUser);

        ClassResponse response = ClassResponse.builder()
                .classId(1L)
                .className("BCA 1st Semester")
                .build();

        when(classService.getClassesForUser(10L, UserRole.STUDENT)).thenReturn(List.of(response));

        mockMvc.perform(get("/api/classes/my-classes"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].classId").value(1));
    }
}
