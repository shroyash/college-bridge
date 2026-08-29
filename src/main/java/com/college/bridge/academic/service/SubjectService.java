package com.college.bridge.academic.service;

import com.college.bridge.academic.dto.ClassStudentResponse;
import com.college.bridge.academic.dto.SubjectDetailResponse;
import com.college.bridge.academic.dto.SubjectResponse;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.entity.TeacherAssignment;
import com.college.bridge.academic.repository.SubjectEnrollmentRepository;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.academic.repository.TeacherAssignmentRepository;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.repository.StudentRepository;
import com.college.bridge.auth.repository.TeacherRepository;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.common.exception.TenantMismatchException;
import com.college.bridge.common.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(noRollbackFor = { TenantMismatchException.class, ResourceNotFoundException.class, AccessDeniedException.class })
public class SubjectService {

    private final SubjectRepository subjectRepository;
    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final SubjectEnrollmentRepository subjectEnrollmentRepository;
    private final TeacherAssignmentRepository teacherAssignmentRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true, noRollbackFor = { TenantMismatchException.class, ResourceNotFoundException.class })
    public SubjectResponse getSubjectById(Long subjectId) {
        Subject subject = subjectRepository.findById(subjectId)
                .orElseThrow(() -> new ResourceNotFoundException("Subject", subjectId));

        Long currentTenantId = TenantContext.get();
        if (subject.getAcademicLevel() == null || subject.getAcademicLevel().getProgram() == null
                || subject.getAcademicLevel().getProgram().getInstitution() == null
                || (currentTenantId != null && !subject.getAcademicLevel().getProgram().getInstitution().getInstitutionId().equals(currentTenantId))) {
            throw new TenantMismatchException("Subject not found or does not belong to current institution");
        }

        return SubjectResponse.from(subject);
    }

    @Transactional(readOnly = true, noRollbackFor = { TenantMismatchException.class, ResourceNotFoundException.class })
    public List<SubjectResponse> getSubjectsByLevel(Long levelId) {
        return subjectRepository.findByAcademicLevel_LevelId(levelId)
                .stream()
                .map(SubjectResponse::from)
                .toList();
    }

    @Transactional(readOnly = true, noRollbackFor = { TenantMismatchException.class, ResourceNotFoundException.class })
    public List<SubjectResponse> getAllSubjects() {
        Long tenantId = TenantContext.get();
        if (tenantId == null) {
            return List.of();
        }

        return subjectRepository.findByAcademicLevel_Program_Institution_InstitutionId(tenantId)
                .stream()
                .map(SubjectResponse::from)
                .toList();
    }

    @Transactional(readOnly = true, noRollbackFor = { TenantMismatchException.class, ResourceNotFoundException.class })
    public List<SubjectResponse> searchSubjects(String name) {
        Long tenantId = TenantContext.get();
        if (tenantId == null) {
            return List.of();
        }

        return subjectRepository.findByAcademicLevel_Program_Institution_InstitutionIdAndNameContainingIgnoreCase(tenantId, name)
                .stream()
                .map(SubjectResponse::from)
                .toList();
    }

    @Transactional(readOnly = true, noRollbackFor = { TenantMismatchException.class, ResourceNotFoundException.class })
    public List<SubjectResponse> getSubjectsForStudent(Long studentId) {
        return subjectEnrollmentRepository.findByStudent_StudentId(studentId)
                .stream()
                .map(se -> SubjectResponse.from(se.getSubject()))
                .toList();
    }

    @Transactional(readOnly = true, noRollbackFor = { TenantMismatchException.class, ResourceNotFoundException.class, AccessDeniedException.class })
    public SubjectDetailResponse getSubjectDetails(Long subjectId, UserPrincipal principal) {
        Subject subject = subjectRepository.findById(subjectId)
                .orElseThrow(() -> new ResourceNotFoundException("Subject", subjectId));

        Long tenantId = TenantContext.get();
        Long subjectInstitutionId = subject.getAcademicLevel().getProgram().getInstitution().getInstitutionId();

        if (tenantId != null && !tenantId.equals(subjectInstitutionId)) {
            throw new TenantMismatchException("Access denied: Subject belongs to a different institution");
        }

        // Authorization checks based on Role
        User user = userRepository.findById(principal.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (user.getRole() == UserRole.STUDENT) {
            Student student = studentRepository.findByUser(user)
                    .orElseThrow(() -> new ResourceNotFoundException("Student profile not found"));
            boolean enrolled = subjectEnrollmentRepository.existsByStudent_StudentIdAndSubject_SubjectId(student.getStudentId(), subjectId);
            if (!enrolled) {
                throw new AccessDeniedException("Access denied: You are not enrolled in this subject");
            }
        } else if (user.getRole() == UserRole.TEACHER) {
            Teacher teacher = teacherRepository.findByUser(user)
                    .orElseThrow(() -> new ResourceNotFoundException("Teacher profile not found"));
            boolean assigned = teacherAssignmentRepository.existsByTeacher_TeacherIdAndSubject_SubjectId(teacher.getTeacherId(), subjectId);
            if (!assigned) {
                throw new AccessDeniedException("Access denied: You are not assigned to teach this subject");
            }
        }

        // Construct DTO
        List<ClassStudentResponse> enrolledStudents = subjectEnrollmentRepository.findBySubject_SubjectId(subjectId)
                .stream()
                .map(se -> {
                    Student s = se.getStudent();
                    return ClassStudentResponse.builder()
                            .studentId(s.getStudentId())
                            .userId(s.getUser() != null ? s.getUser().getUserId() : null)
                            .fullName(s.getUser() != null ? s.getUser().getFullName() : "Unknown")
                            .email(s.getUser() != null ? s.getUser().getEmail() : "")
                            .status(s.getUser() != null && s.getUser().getStatus() != null ? s.getUser().getStatus().name() : "ACTIVE")
                            .build();
                })
                .toList();

        Teacher assignedTeacher = subject.getAssignments().stream()
                .findFirst()
                .map(TeacherAssignment::getTeacher)
                .orElse(null);

        SubjectDetailResponse.TeacherInfoDto teacherDto = null;
        if (assignedTeacher != null) {
            teacherDto = SubjectDetailResponse.TeacherInfoDto.builder()
                    .teacherId(assignedTeacher.getTeacherId())
                    .userId(assignedTeacher.getUser() != null ? assignedTeacher.getUser().getUserId() : null)
                    .name(assignedTeacher.getUser() != null ? assignedTeacher.getUser().getFullName() : "Unknown")
                    .email(assignedTeacher.getUser() != null ? assignedTeacher.getUser().getEmail() : "")
                    .build();
        }

        return SubjectDetailResponse.builder()
                .subjectId(subject.getSubjectId())
                .subjectName(subject.getName())
                .code(subject.getCode())
                .creditHours(subject.getCreditHours())
                .academicLevel(SubjectDetailResponse.AcademicLevelInfoDto.builder()
                        .levelId(subject.getAcademicLevel().getLevelId())
                        .name(subject.getAcademicLevel().getName())
                        .levelNumber(subject.getAcademicLevel().getLevelNumber())
                        .type(subject.getAcademicLevel().getType())
                        .build())
                .academicProgram(SubjectDetailResponse.AcademicProgramInfoDto.builder()
                        .programId(subject.getAcademicLevel().getProgram().getProgramId())
                        .name(subject.getAcademicLevel().getProgram().getName())
                        .code(subject.getAcademicLevel().getProgram().getCode())
                        .build())
                .teacher(teacherDto)
                .studentCount(enrolledStudents.size())
                .students(enrolledStudents)
                .build();
    }
}