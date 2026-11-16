package com.college.bridge.academic.service;

import com.college.bridge.academic.dto.ClassDetailResponse;
import com.college.bridge.academic.dto.ClassStudentResponse;
import com.college.bridge.academic.dto.ClassTeacherResponse;
import com.college.bridge.academic.entity.AcademicLevel;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.entity.TeacherAssignment;
import com.college.bridge.academic.mapper.SubjectMapper;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.repository.StudentRepository;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.common.exception.TenantMismatchException;
import com.college.bridge.common.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StudentAcademicService {

    private final StudentRepository studentRepository;
    private final SubjectRepository subjectRepository;
    private final SubjectMapper subjectMapper;

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

        Student student = studentRepository
                .findByStudentIdAndUser_Institution_InstitutionId(studentId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Student not found with ID: " + studentId));

        AcademicLevel level = student.getAcademicLevel();
        if (level == null) {
            throw new ResourceNotFoundException("Student is not currently assigned to any academic level.");
        }

        List<Student> classmates = studentRepository
                .findByAcademicLevel_LevelIdAndUser_Institution_InstitutionId(level.getLevelId(), tenantId);

        List<ClassStudentResponse> studentResponses = subjectMapper.toClassStudentResponseList(classmates);

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
            List<String> subjectNames = teacherSubjects.stream().map(Subject::getName).toList();
            teacherResponses.add(subjectMapper.toClassTeacherResponse(teacher, subjectNames));
        }

        return subjectMapper.toClassDetailResponse(level, studentResponses, teacherResponses);
    }

    private Long requireTenant() {
        Long tenantId = TenantContext.get();
        if (tenantId == null) {
            throw new TenantMismatchException("Tenant context missing.");
        }
        return tenantId;
    }
}
