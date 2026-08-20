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
import com.college.bridge.common.exception.TenantMismatchException;
import com.college.bridge.common.tenant.TenantContext;
import com.college.bridge.institution.entity.Institution;
import com.college.bridge.institution.repository.InstitutionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(noRollbackFor = {TenantMismatchException.class, ResourceNotFoundException.class})
public class ClassService {

    private final ClassRepository classRepository;
    private final ClassEnrollmentRepository classEnrollmentRepository;
    private final TeacherRepository teacherRepository;
    private final StudentRepository studentRepository;
    private final InstitutionRepository institutionRepository;

    @Transactional(readOnly = true, noRollbackFor = {TenantMismatchException.class, ResourceNotFoundException.class})
    public ClassResponse getClassById(Long classId) {
        ClassEntity classEntity = classRepository.findById(classId)
                .orElseThrow(() -> new ResourceNotFoundException("Class", classId));

        Long currentTenantId = TenantContext.get();
        if (classEntity.getInstitution() == null || currentTenantId == null || !classEntity.getInstitution().getInstitutionId().equals(currentTenantId)) {
            throw new TenantMismatchException("Class not found or does not belong to current institution");
        }

        return toResponse(classEntity);
    }

    public ClassResponse createClass(CreateClassRequest request) {
        Long tenantId = TenantContext.get();
        if (tenantId == null) {
            throw new BusinessRuleException("Tenant context is required to create a class.");
        }

        Institution institution = institutionRepository.findById(tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Institution not found with id: " + tenantId));

        String className = request.getFaculty() + " Semester " + request.getSemester();
        String fcmTopicId = "class-" + UUID.randomUUID().toString().replace("-", "").substring(0, 12);

        ClassEntity classEntity = ClassEntity.builder()
                .institution(institution)
                .className(className)
                .faculty(request.getFaculty())
                .semester(request.getSemester())
                .fcmTopicId(fcmTopicId)
                .build();

        ClassEntity saved = classRepository.save(classEntity);
        log.info("Admin created class '{}' (id={}) for institution {}.", saved.getClassName(), saved.getClassId(), tenantId);
        return toResponse(saved);
    }

    public ClassResponse assignTeacher(Long classId, AssignTeacherRequest request) {
        ClassEntity classEntity = classRepository.findById(classId)
                .orElseThrow(() -> new ResourceNotFoundException("Class", classId));

        Long currentTenantId = TenantContext.get();
        if (classEntity.getInstitution() == null || currentTenantId == null || !classEntity.getInstitution().getInstitutionId().equals(currentTenantId)) {
            throw new TenantMismatchException("Class not found or does not belong to current institution");
        }

        Teacher teacher = teacherRepository.findById(request.getTeacherId())
                .orElseThrow(() -> new ResourceNotFoundException("Teacher", request.getTeacherId()));

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

    @Transactional(readOnly = true, noRollbackFor = {TenantMismatchException.class, ResourceNotFoundException.class})
    public List<ClassResponse> getClassesForTeacher(Long userId) {
        Long tenantId = TenantContext.get();
        if (tenantId == null) {
            return List.of();
        }

        Teacher teacher = teacherRepository.findAll().stream()
                .filter(t -> t.getUser().getUserId().equals(userId))
                .findFirst()
                .orElseThrow(() -> new ResourceNotFoundException(
                        "No teacher profile found for user id: " + userId));

        return classRepository.findByInstitution_InstitutionIdAndTeacher(tenantId, teacher).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true, noRollbackFor = {TenantMismatchException.class, ResourceNotFoundException.class})
    public List<ClassResponse> getClassesForStudent(Long userId) {
        Long tenantId = TenantContext.get();
        if (tenantId == null) {
            return List.of();
        }

        Student student = studentRepository.findAll().stream()
                .filter(s -> s.getUser().getUserId().equals(userId))
                .findFirst()
                .orElseThrow(() -> new ResourceNotFoundException(
                        "No student profile found for user id: " + userId));

        List<ClassResponse> enrolled = classEnrollmentRepository.findByStudent(student).stream()
                .filter(e -> e.getClassEntity().getInstitution() != null && e.getClassEntity().getInstitution().getInstitutionId().equals(tenantId))
                .map(e -> toResponse(e.getClassEntity()))
                .toList();

        if (!enrolled.isEmpty()) {
            return enrolled;
        }

        if (student.getAcademicClass() != null) {
            return classRepository.findByInstitution_InstitutionIdAndFacultyAndSemester(
                    tenantId,
                    student.getAcademicClass().getFaculty(),
                    student.getAcademicClass().getSemester()
            ).stream().map(this::toResponse).toList();
        }

        return List.of();
    }

    @Transactional(readOnly = true, noRollbackFor = {TenantMismatchException.class, ResourceNotFoundException.class})
    public List<ClassResponse> getAllClasses() {
        Long tenantId = TenantContext.get();
        if (tenantId == null) {
            return List.of();
        }

        return classRepository.findByInstitution_InstitutionId(tenantId).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true, noRollbackFor = {TenantMismatchException.class, ResourceNotFoundException.class})
    public List<ClassResponse> getClassesForUser(Long userId, UserRole role) {
        if (role == UserRole.TEACHER) {
            return getClassesForTeacher(userId);
        } else if (role == UserRole.STUDENT) {
            return getClassesForStudent(userId);
        } else if (role == UserRole.ADMIN) {
            return getAllClasses();
        }
        return List.of();
    }

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
