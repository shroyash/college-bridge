package com.college.bridge.academic.service;

import com.college.bridge.academic.dto.AcademicClassResponse;
import com.college.bridge.academic.dto.ClassDetailResponse;
import com.college.bridge.academic.dto.ClassStudentResponse;
import com.college.bridge.academic.dto.ClassTeacherResponse;
import com.college.bridge.academic.entity.AcademicClass;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.entity.TeacherAssignment;
import com.college.bridge.academic.repository.AcademicClassRepository;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.academic.repository.TeacherAssignmentRepository;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.repository.StudentRepository;
import com.college.bridge.auth.repository.TeacherRepository;
import com.college.bridge.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@Service
@RequiredArgsConstructor
@Slf4j
public class TeacherAcademicService {

    private final TeacherRepository teacherRepository;
    private final TeacherAssignmentRepository teacherAssignmentRepository;
    private final AcademicClassRepository academicClassRepository;
    private final StudentRepository studentRepository;
    private final SubjectRepository subjectRepository;

    @Transactional(readOnly = true)
    public List<AcademicClassResponse> getTeacherClasses(Long teacherId) {
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher not found with ID: " + teacherId));

        Long institutionId = teacher.getUser().getInstitution().getInstitutionId();
        List<TeacherAssignment> assignments = teacherAssignmentRepository.findByTeacherTeacherId(teacherId);

        List<AcademicClass> subjectClasses = assignments.stream()
                .map(a -> academicClassRepository.findByInstitution_InstitutionIdAndFacultyAndSemester(
                        institutionId, a.getSubject().getFaculty(), a.getSubject().getSemester()
                ))
                .flatMap(java.util.Optional::stream)
                .toList();

        List<AcademicClass> classTeacherClasses = academicClassRepository.findByInstitution_InstitutionIdAndClassTeacher_TeacherId(institutionId, teacherId);

        List<AcademicClass> classes = Stream.concat(subjectClasses.stream(), classTeacherClasses.stream())
                .distinct()
                .toList();

        return classes.stream().map(ac -> {
            int count = (int) studentRepository.countByAcademicClass_ClassId(ac.getClassId());
            return AcademicClassResponse.from(ac, count);
        }).toList();
    }

    @Transactional(readOnly = true)
    public ClassDetailResponse getTeacherClassDetails(Long teacherId, Long classId) {
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher not found: " + teacherId));

        Long institutionId = teacher.getUser().getInstitution().getInstitutionId();
        AcademicClass academicClass = academicClassRepository.findById(classId)
                .orElseThrow(() -> new ResourceNotFoundException("Academic class not found: " + classId));

        if (!academicClass.getInstitution().getInstitutionId().equals(institutionId)) {
            throw new ResourceNotFoundException("Class does not belong to the teacher's institution");
        }

        boolean isSubjectAssigned = teacherAssignmentRepository.existsByTeacher_TeacherIdAndSubject_FacultyAndSubject_Semester(
                teacherId, academicClass.getFaculty(), academicClass.getSemester());
        boolean isClassTeacher = academicClass.getClassTeacher() != null && academicClass.getClassTeacher().getTeacherId().equals(teacherId);

        if (!isSubjectAssigned && !isClassTeacher) {
            throw new ResourceNotFoundException("Teacher is not authorized to access this class");
        }

        List<Student> students = studentRepository.findByAcademicClass_ClassId(classId);
        List<ClassStudentResponse> studentResponses = students.stream().map(s -> ClassStudentResponse.builder()
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
            Teacher t = entry.getKey();
            List<Subject> teacherSubjects = entry.getValue();
            boolean isCT = academicClass.getClassTeacher() != null &&
                    academicClass.getClassTeacher().getTeacherId().equals(t.getTeacherId());

            teacherResponses.add(ClassTeacherResponse.builder()
                    .teacherId(t.getTeacherId())
                    .userId(t.getUser() != null ? t.getUser().getUserId() : null)
                    .fullName(t.getUser() != null ? t.getUser().getFullName() : "Unknown")
                    .email(t.getUser() != null ? t.getUser().getEmail() : "")
                    .assignedSubjects(teacherSubjects.stream().map(Subject::getName).toList())
                    .isClassTeacher(isCT)
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
