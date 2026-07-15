package com.college.bridge.clazz.service;

import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.repository.StudentRepository;
import com.college.bridge.auth.repository.TeacherRepository;
import com.college.bridge.clazz.dto.AssignTeacherRequest;
import com.college.bridge.clazz.dto.ClassResponse;
import com.college.bridge.clazz.dto.CreateClassRequest;
import com.college.bridge.clazz.entity.ClassEntity;
import com.college.bridge.clazz.repository.ClassEnrollmentRepository;
import com.college.bridge.clazz.repository.ClassRepository;
import com.college.bridge.common.exception.BusinessRuleException;
import com.college.bridge.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Manages academic class creation and teacher assignment.
 * <p>
 * Only admins can create classes and assign teachers.
 * Teachers and students can query their own class memberships.
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class ClassService {

    private final ClassRepository classRepository;
    private final ClassEnrollmentRepository classEnrollmentRepository;
    private final TeacherRepository teacherRepository;
    private final StudentRepository studentRepository;

    // -------------------------------------------------------------------------
    // Admin — create class
    // -------------------------------------------------------------------------

    /**
     * Creates a new teaching class for a given faculty, semester, and optional subject.
     * The FCM topic ID is auto-generated.
     */
    public ClassResponse createClass(CreateClassRequest request) {
        // Build a human-readable class name
        String className = request.getFaculty().name() + " Semester " + request.getSemester();
        String fcmTopicId = "class-" + UUID.randomUUID().toString().replace("-", "").substring(0, 12);

        ClassEntity classEntity = ClassEntity.builder()
                .className(className)
                .faculty(request.getFaculty())
                .semester(request.getSemester())
                .fcmTopicId(fcmTopicId)
                .build();

        ClassEntity saved = classRepository.save(classEntity);
        log.info("Admin created class '{}' (id={}).", saved.getClassName(), saved.getClassId());
        return toResponse(saved);
    }

    // -------------------------------------------------------------------------
    // Admin — assign teacher
    // -------------------------------------------------------------------------

    /**
     * Assigns a verified teacher to an existing class.
     * <p>
     * Business rules:
     * <ul>
     *   <li>Teacher must exist and hold ROLE_TEACHER.</li>
     *   <li>Class must exist.</li>
     * </ul>
     */
    public ClassResponse assignTeacher(Long classId, AssignTeacherRequest request) {
        ClassEntity classEntity = classRepository.findById(classId)
                .orElseThrow(() -> new ResourceNotFoundException("Class", classId));

        Teacher teacher = teacherRepository.findById(request.getTeacherId())
                .orElseThrow(() -> new ResourceNotFoundException("Teacher", request.getTeacherId()));

        // Confirm the teacher's user actually holds ROLE_TEACHER
        if (teacher.getUser().getRole() != UserRole.TEACHER) {
            throw new BusinessRuleException(
                    "User " + teacher.getUser().getEmail() + " is not a verified teacher.");
        }

        classEntity.setTeacher(teacher);
        ClassEntity saved = classRepository.save(classEntity);

        log.info("Teacher {} assigned to class '{}' (classId={}).",
                teacher.getUser().getEmail(), saved.getClassName(), classId);

        return toResponse(saved);
    }

    // -------------------------------------------------------------------------
    // Teacher — get own classes
    // -------------------------------------------------------------------------

    @Transactional(readOnly = true)
    public List<ClassResponse> getClassesForTeacher(Long userId) {
        Teacher teacher = teacherRepository.findAll().stream()
                .filter(t -> t.getUser().getUserId().equals(userId))
                .findFirst()
                .orElseThrow(() -> new ResourceNotFoundException(
                        "No teacher profile found for user id: " + userId));

        return classRepository.findByTeacher(teacher).stream()
                .map(this::toResponse)
                .toList();
    }

    // -------------------------------------------------------------------------
    // Student — get enrolled classes
    // -------------------------------------------------------------------------

    @Transactional(readOnly = true)
    public List<ClassResponse> getClassesForStudent(Long userId) {
        Student student = studentRepository.findAll().stream()
                .filter(s -> s.getUser().getUserId().equals(userId))
                .findFirst()
                .orElseThrow(() -> new ResourceNotFoundException(
                        "No student profile found for user id: " + userId));

        return classEnrollmentRepository.findByStudent(student).stream()
                .map(e -> toResponse(e.getClassEntity()))
                .toList();
    }

    // -------------------------------------------------------------------------
    // Mapper
    // -------------------------------------------------------------------------

    private ClassResponse toResponse(ClassEntity cls) {
        ClassResponse.ClassResponseBuilder builder = ClassResponse.builder()
                .classId(cls.getClassId())
                .className(cls.getClassName())
                .subject(cls.getSubject())
                .faculty(cls.getFaculty())
                .semester(cls.getSemester())
                .fcmTopicId(cls.getFcmTopicId());

        if (cls.getTeacher() != null) {
            builder.teacherName(cls.getTeacher().getUser().getName())
                   .teacherEmail(cls.getTeacher().getUser().getEmail());
        }

        return builder.build();
    }
}
