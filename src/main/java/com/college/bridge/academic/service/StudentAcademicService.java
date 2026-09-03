package com.college.bridge.academic.service;

import com.college.bridge.academic.dto.ClassDetailResponse;
import com.college.bridge.academic.dto.ClassStudentResponse;
import com.college.bridge.academic.dto.ClassTeacherResponse;
import com.college.bridge.academic.entity.AcademicLevel;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.entity.TeacherAssignment;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.repository.StudentRepository;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.common.exception.TenantMismatchException;
import com.college.bridge.common.tenant.TenantContext;
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

    /**
     * Returns full class detail for a student: classmates, subjects, and assigned teachers.
     * <p>
     * Security: student and classmates are both fetched with tenant scope so a caller
     * knowing a studentId from another institution cannot extract their class roster.
     * </p>
     */
    @Transactional(readOnly = true)
    public ClassDetailResponse getStudentClassDetails(Long studentId) {
        Long tenantId = requireTenant();

        // C-4 FIX: scope student lookup to current tenant
        Student student = studentRepository
                .findByStudentIdAndUser_Institution_InstitutionId(studentId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Student not found with ID: " + studentId));

        AcademicLevel level = student.getAcademicLevel();
        if (level == null) {
            throw new ResourceNotFoundException("Student is not currently assigned to any academic level.");
        }

        // I-1 FIX: scope classmate lookup to current tenant
        List<Student> classmates = studentRepository
                .findByAcademicLevel_LevelIdAndUser_Institution_InstitutionId(level.getLevelId(), tenantId);

        List<ClassStudentResponse> studentResponses = classmates.stream()
                .map(s -> ClassStudentResponse.builder()
                        .studentId(s.getStudentId())
                        .userId(s.getUser() != null ? s.getUser().getUserId() : null)
                        .fullName(s.getUser() != null ? s.getUser().getFullName() : "Unknown")
                        .email(s.getUser() != null ? s.getUser().getEmail() : "")
                        .status(s.getUser() != null && s.getUser().getStatus() != null
                                ? s.getUser().getStatus().name() : "ACTIVE")
                        .build())
                .toList();

        // EntityGraph on findByAcademicLevel_LevelIdAndDeletedFalse eagerly fetches assignments+teacher+user
        List<Subject> subjects = subjectRepository.findByAcademicLevel_LevelIdAndDeletedFalse(level.getLevelId());

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

            teacherResponses.add(ClassTeacherResponse.builder()
                    .teacherId(teacher.getTeacherId())
                    .userId(teacher.getUser() != null ? teacher.getUser().getUserId() : null)
                    .fullName(teacher.getUser() != null ? teacher.getUser().getFullName() : "Unknown")
                    .email(teacher.getUser() != null ? teacher.getUser().getEmail() : "")
                    .assignedSubjects(teacherSubjects.stream().map(Subject::getName).toList())
                    .isClassTeacher(false)
                    .build());
        }

        String displayName = level.getProgram() != null
                ? level.getProgram().getCode() + " - " + level.getName()
                : level.getName();

        return ClassDetailResponse.builder()
                .classId(level.getLevelId())
                .displayName(displayName)
                .faculty(level.getProgram() != null ? level.getProgram().getCode() : "")
                .semester(level.getLevelNumber())
                .totalStudents(studentResponses.size())
                .institutionId(level.getProgram() != null && level.getProgram().getInstitution() != null
                        ? level.getProgram().getInstitution().getInstitutionId() : null)
                .institutionName(level.getProgram() != null && level.getProgram().getInstitution() != null
                        ? level.getProgram().getInstitution().getName() : "")
                .createdBy("Institution Admin")
                .createdAt(level.getCreatedAt() != null ? level.getCreatedAt().toString() : "")
                .students(studentResponses)
                .teachers(teacherResponses)
                .build();
    }

    private Long requireTenant() {
        Long tenantId = TenantContext.get();
        if (tenantId == null) {
            throw new TenantMismatchException("Tenant context missing.");
        }
        return tenantId;
    }
}
