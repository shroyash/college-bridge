package com.college.bridge.academic;

import com.college.bridge.academic.dto.SubjectResponse;
import com.college.bridge.academic.entity.AcademicClass;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.academic.service.SubjectService;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.repository.StudentRepository;
import com.college.bridge.common.exception.ResourceNotFoundException;
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
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class SubjectServiceTest {

        @Mock
        private SubjectRepository subjectRepository;

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
        @DisplayName("Should return subjects for student found by studentId")
        void testGetSubjectsForStudent_byStudentId() {
                AcademicClass academicClass = AcademicClass.builder()
                                .classId(10L)
                                .faculty("BIT")
                                .semester(1)
                                .build();

                User user = User.builder()
                                .userId(5L)
                                .email("student@test.com")
                                .build();

                Student student = Student.builder()
                                .studentId(1L)
                                .user(user)
                                .academicClass(academicClass)
                                .build();

                Subject subject = Subject.builder()
                                .subjectId(20L)
                                .name("Java Programming")
                                .faculty("BIT")
                                .semester(1)
                                .creditHours(3)
                                .build();

                when(studentRepository.findByStudentId(1L)).thenReturn(Optional.of(student));
                when(subjectRepository.findByInstitution_InstitutionIdAndFacultyAndSemester(100L, "BIT", 1))
                                .thenReturn(List.of(subject));

                List<SubjectResponse> responses = subjectService.getSubjectsForStudent(1L);

                assertNotNull(responses);
                assertEquals(1, responses.size());
                assertEquals("Java Programming", responses.get(0).getName());
                assertEquals("BIT", responses.get(0).getFaculty());
                assertEquals(1, responses.get(0).getSemester());

                verify(studentRepository, times(1)).findByStudentId(1L);
        }

        @Test
        @DisplayName("Should return subjects for student found by userId fallback")
        void testGetSubjectsForStudent_byUserIdFallback() {
                AcademicClass academicClass = AcademicClass.builder()
                                .classId(10L)
                                .faculty("BIT")
                                .semester(2)
                                .build();

                User user = User.builder()
                                .userId(5L)
                                .email("student@test.com")
                                .build();

                Student student = Student.builder()
                                .studentId(1L)
                                .user(user)
                                .academicClass(academicClass)
                                .build();

                Subject subject = Subject.builder()
                                .subjectId(21L)
                                .name("Data Structures")
                                .faculty("BIT")
                                .semester(2)
                                .creditHours(3)
                                .build();

                when(studentRepository.findByStudentId(5L)).thenReturn(Optional.empty());
                when(studentRepository.findByUser_UserId(5L)).thenReturn(Optional.of(student));
                when(subjectRepository.findByInstitution_InstitutionIdAndFacultyAndSemester(100L, "BIT", 2))
                                .thenReturn(List.of(subject));

                List<SubjectResponse> responses = subjectService.getSubjectsForStudent(5L);

                assertNotNull(responses);
                assertEquals(1, responses.size());
                assertEquals("Data Structures", responses.get(0).getName());

                verify(studentRepository, times(1)).findByStudentId(5L);
                verify(studentRepository, times(1)).findByUser_UserId(5L);
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when student profile is missing")
        void testGetSubjectsForStudent_NotFound() {
                when(studentRepository.findByStudentId(99L)).thenReturn(Optional.empty());
                when(studentRepository.findByUser_UserId(99L)).thenReturn(Optional.empty());

                assertThrows(ResourceNotFoundException.class, () -> subjectService.getSubjectsForStudent(99L));
        }
}
