package com.college.bridge.academic;

import com.college.bridge.academic.dto.SubjectResponse;
import com.college.bridge.academic.entity.AcademicLevel;
import com.college.bridge.academic.entity.AcademicProgram;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.entity.SubjectEnrollment;
import com.college.bridge.academic.repository.SubjectEnrollmentRepository;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.academic.service.SubjectService;
import com.college.bridge.auth.entity.Student;
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
        AcademicProgram program = AcademicProgram.builder()
                .programId(1L)
                .name("Bachelor of Computer Application")
                .code("BCA")
                .build();

        AcademicLevel level = AcademicLevel.builder()
                .levelId(10L)
                .program(program)
                .name("1st Semester")
                .levelNumber(1)
                .build();

        Student student = Student.builder()
                .studentId(1L)
                .academicLevel(level)
                .build();

        Subject subject = Subject.builder()
                .subjectId(20L)
                .academicLevel(level)
                .name("Java Programming")
                .code("CACS201")
                .creditHours(3)
                .build();

        SubjectEnrollment enrollment = SubjectEnrollment.builder()
                .enrollmentId(100L)
                .student(student)
                .subject(subject)
                .build();

        when(subjectEnrollmentRepository.findByStudent_StudentId(1L)).thenReturn(List.of(enrollment));

        List<SubjectResponse> responses = subjectService.getSubjectsForStudent(1L);

        assertNotNull(responses);
        assertEquals(1, responses.size());
        assertEquals("Java Programming", responses.get(0).getName());
        assertEquals("CACS201", responses.get(0).getCode());
        assertEquals("1st Semester", responses.get(0).getLevelName());

        verify(subjectEnrollmentRepository, times(1)).findByStudent_StudentId(1L);
    }
}
