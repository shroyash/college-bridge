package com.college.bridge.academic;

import com.college.bridge.academic.dto.SubjectResponse;
import com.college.bridge.academic.entity.AcademicLevel;
import com.college.bridge.academic.entity.AcademicProgram;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.entity.SubjectEnrollment;
import com.college.bridge.academic.mapper.SubjectMapper;
import com.college.bridge.academic.repository.SubjectEnrollmentRepository;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.academic.repository.TeacherAssignmentRepository;
import com.college.bridge.academic.service.SubjectService;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.repository.StudentRepository;
import com.college.bridge.common.tenant.TenantContext;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class SubjectServiceTest {

    @Mock
    private SubjectRepository subjectRepository;

    @Mock
    private SubjectEnrollmentRepository subjectEnrollmentRepository;

    @Mock
    private TeacherAssignmentRepository teacherAssignmentRepository;

    @Mock
    private SubjectMapper subjectMapper;

    @Mock
    private StudentRepository studentRepository;

    @InjectMocks
    private SubjectService subjectService;

    @BeforeEach
    void setUp() {
        TenantContext.set(100L);
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
    }

    @Test
    @DisplayName("Should return subjects for student by studentId")
    void testGetSubjectsForStudent_byStudentId() {
        SubjectResponse expectedResponse = SubjectResponse.builder()
                .subjectId(20L)
                .name("Java Programming")
                .code("CACS201")
                .creditHours(3)
                .levelId(10L)
                .levelName("1st Semester")
                .programId(1L)
                .programName("Bachelor of Computer Application")
                .build();

        when(studentRepository.existsByStudentIdAndUser_Institution_InstitutionId(1L, 100L)).thenReturn(true);
        when(subjectEnrollmentRepository.findSubjectsForStudent(1L, 100L)).thenReturn(List.of(expectedResponse));

        List<SubjectResponse> responses = subjectService.getSubjectsForStudent(1L);

        assertNotNull(responses);
        assertEquals(1, responses.size());
        assertEquals("Java Programming", responses.get(0).getName());
        assertEquals("CACS201", responses.get(0).getCode());
        assertEquals("1st Semester", responses.get(0).getLevelName());

        verify(studentRepository, times(1)).existsByStudentIdAndUser_Institution_InstitutionId(1L, 100L);
        verify(subjectEnrollmentRepository, times(1)).findSubjectsForStudent(1L, 100L);
    }
}
