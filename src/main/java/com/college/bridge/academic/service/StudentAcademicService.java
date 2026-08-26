package com.college.bridge.academic.service;

import com.college.bridge.academic.dto.ClassDetailResponse;
import com.college.bridge.academic.dto.ClassStudentResponse;
import com.college.bridge.academic.dto.ClassTeacherResponse;
import com.college.bridge.academic.entity.AcademicClass;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.entity.TeacherAssignment;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.repository.StudentRepository;
import com.college.bridge.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class StudentAcademicService {

    private final StudentRepository studentRepository;
    private final SubjectRepository subjectRepository;

    @Transactional(readOnly = true)
    public ClassDetailResponse getStudentClassDetails(Long studentId) {
        Student student = studentRepository.findByStudentId(studentId)
                .orElseThrow(() -> new ResourceNotFoundException("Student not found with ID: " + studentId));

        AcademicClass academicClass = student.getAcademicClass();
        if (academicClass == null) {
            throw new ResourceNotFoundException("Student is not currently assigned to any class.");
        }

        Long institutionId = student.getUser().getInstitution().getInstitutionId();
        List<Student> classmates = studentRepository.findByAcademicClass_ClassId(academicClass.getClassId());

        List<ClassStudentResponse> studentResponses = classmates.stream().map(s -> ClassStudentResponse.builder()
                .studentId(s.getStudentId())
                .userId(s.getUser() != null ? s.getUser().getUserId() : null)
                .fullName(s.getUser() != null ? s.getUser().getFullName() : "Unknown")
                .email(s.getUser() != null ? s.getUser().getEmail() : "")
                .status(s.getUser() != null && s.getUser().getStatus() != null ? s.getUser().getStatus().name() : "ACTIVE")
                .build()).toList();

        List<Subject> subjects = subjectRepository.findByInstitution_InstitutionIdAndFacultyAndSemester(
                institutionId, academicClass.getFaculty(), academicClass.getSemester()
        );

        List<ClassTeacherResponse> teacherResponses = new ArrayList<>();
        Map<Teacher, List<Subject>> teacherSubjectMap = subjects.stream()
                .flatMap(sub -> sub.getAssignments().stream())
                .collect(Collectors.groupingBy(
                        TeacherAssignment::getTeacher,
                        Collectors.mapping(TeacherAssignment::getSubject, Collectors.toList())
                ));

        for (Map.Entry<Teacher, List<Subject>> entry : teacherSubjectMap.entrySet()) {
            Teacher teacher = entry.getKey();
            List<Subject> teacherSubjects = entry.getValue();
            boolean isClassTeacher = academicClass.getClassTeacher() != null &&
                    academicClass.getClassTeacher().getTeacherId().equals(teacher.getTeacherId());

            teacherResponses.add(ClassTeacherResponse.builder()
                    .teacherId(teacher.getTeacherId())
                    .userId(teacher.getUser() != null ? teacher.getUser().getUserId() : null)
                    .fullName(teacher.getUser() != null ? teacher.getUser().getFullName() : "Unknown")
                    .email(teacher.getUser() != null ? teacher.getUser().getEmail() : "")
                    .assignedSubjects(teacherSubjects.stream().map(Subject::getName).toList())
                    .isClassTeacher(isClassTeacher)
                    .build());
        }

        if (academicClass.getClassTeacher() != null) {
            Teacher ct = academicClass.getClassTeacher();
            if (teacherResponses.stream().noneMatch(tr -> tr.getTeacherId().equals(ct.getTeacherId()))) {
                teacherResponses.add(ClassTeacherResponse.builder()
                        .teacherId(ct.getTeacherId())
                        .userId(ct.getUser() != null ? ct.getUser().getUserId() : null)
                        .fullName(ct.getUser() != null ? ct.getUser().getFullName() : "Unknown")
                        .email(ct.getUser() != null ? ct.getUser().getEmail() : "")
                        .assignedSubjects(List.of())
                        .isClassTeacher(true)
                        .build());
            }
        }

        String classTeacherName = academicClass.getClassTeacher() != null && academicClass.getClassTeacher().getUser() != null
                ? academicClass.getClassTeacher().getUser().getFullName()
                : null;

        return ClassDetailResponse.builder()
                .classId(academicClass.getClassId())
                .displayName(academicClass.getDisplayName())
                .faculty(academicClass.getFaculty())
                .semester(academicClass.getSemester())
                .totalStudents(studentResponses.size())
                .classTeacherId(academicClass.getClassTeacher() != null ? academicClass.getClassTeacher().getTeacherId() : null)
                .classTeacherName(classTeacherName)
                .institutionId(academicClass.getInstitution().getInstitutionId())
                .institutionName(academicClass.getInstitution().getName())
                .createdBy("Institution Admin")
                .createdAt(academicClass.getCreatedAt() != null ? academicClass.getCreatedAt().toString() : "")
                .students(studentResponses)
                .teachers(teacherResponses)
                .build();
    }
}
