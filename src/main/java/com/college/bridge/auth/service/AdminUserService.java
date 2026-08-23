package com.college.bridge.auth.service;

import java.security.Principal;
import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.college.bridge.academic.entity.AcademicClass;
import com.college.bridge.academic.repository.AcademicClassRepository;
import com.college.bridge.academic.repository.SubjectEnrollmentRepository;
import com.college.bridge.auth.dto.BulkTransferRequest;
import com.college.bridge.auth.dto.BulkTransferResponse;
import com.college.bridge.auth.dto.ChangeRoleRequest;
import com.college.bridge.auth.dto.RejectTeacherRequest;
import com.college.bridge.auth.dto.StudentFilterOptionsResponse;
import com.college.bridge.auth.dto.UserProfileResponse;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.entity.UserStatus;
import com.college.bridge.auth.exception.InvalidRoleException;
import com.college.bridge.auth.exception.TeacherAlreadyVerifiedException;
import com.college.bridge.auth.exception.UserNotFoundException;
import com.college.bridge.auth.mapper.UserMapper;
import com.college.bridge.auth.repository.RefreshTokenRepository;
import com.college.bridge.auth.repository.StudentRepository;
import com.college.bridge.auth.repository.TeacherRepository;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.auth.specification.UserSpecification;
import com.college.bridge.common.exception.BusinessRuleException;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.common.exception.TenantMismatchException;
import com.college.bridge.verification.entity.VerificationStatus;
import com.college.bridge.verification.repository.TeacherVerificationRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class AdminUserService {

    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final TeacherVerificationRepository verificationRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final AcademicClassRepository academicClassRepository;
    private final SubjectEnrollmentRepository subjectEnrollmentRepository;
    private final UserMapper userMapper;
    private final UserTokenRevocationService userTokenRevocationService;

    @Transactional(readOnly = true)
    public Page<UserProfileResponse> getAllUsers(Pageable pageable) {
        return userRepository.findAll(pageable)
                .map(user -> {
                    Student student = null;
                    if (UserRole.STUDENT.equals(user.getRole())) {
                        student = studentRepository.findByUser(user).orElse(null);
                    }
                    return userMapper.toProfileResponse(user, student);
                });
    }

    @Transactional(readOnly = true)
    public Page<UserProfileResponse> searchUsers(String query, Pageable pageable) {
        Specification<User> spec = UserSpecification.search(query);
        return userRepository.findAll(spec, pageable)
                .map(user -> {
                    Student student = null;
                    if (UserRole.STUDENT.equals(user.getRole())) {
                        student = studentRepository.findByUser(user).orElse(null);
                    }
                    return userMapper.toProfileResponse(user, student);
                });
    }

    @Transactional(readOnly = true)
    public Page<UserProfileResponse> filterUsers(UserRole role, UserStatus status, Pageable pageable) {
        Specification<User> spec = UserSpecification.hasRole(role);

        Page<User> userPage = userRepository.findAll(spec, pageable);

        List<Long> userIds = userPage.getContent().stream()
                .map(User::getUserId)
                .toList();

        Map<Long, Student> studentByUserId = Collections.emptyMap();
        Map<Long, Teacher> teacherByUserId = Collections.emptyMap();

        if (UserRole.STUDENT.equals(role) && !userIds.isEmpty()) {
            studentByUserId = studentRepository.findByUser_UserIdIn(userIds).stream()
                    .collect(Collectors.toMap(s -> s.getUser().getUserId(), Function.identity()));
        } else if (UserRole.TEACHER.equals(role) && !userIds.isEmpty()) {
            teacherByUserId = teacherRepository.findByUser_UserIdIn(userIds).stream()
                    .collect(Collectors.toMap(t -> t.getUser().getUserId(), Function.identity()));
        }

        final Map<Long, Student> finalStudentMap = studentByUserId;
        final Map<Long, Teacher> finalTeacherMap = teacherByUserId;

        return userPage.map(user -> {
            Student student = finalStudentMap.get(user.getUserId());
            Teacher teacher = finalTeacherMap.get(user.getUserId());
            return userMapper.toProfileResponse(user, student, teacher);
        });
    }

    @Transactional(readOnly = true)
    public Page<UserProfileResponse> getStudentsFiltered(Principal principal, String faculty, Integer semester, String search, Pageable pageable) {
        Long tenantId = getTenantId(principal);
        String searchPattern = (search != null && !search.isBlank()) ? search.trim() : null;
        String facultyParam = (faculty != null && !faculty.isBlank()) ? faculty.trim() : null;

        return studentRepository.findStudentsFiltered(tenantId, facultyParam, semester, searchPattern, pageable)
                .map(student -> userMapper.toProfileResponse(student.getUser(), student));
    }

    @Transactional(readOnly = true)
    public StudentFilterOptionsResponse getStudentFilterOptions(Principal principal) {
        Long tenantId = getTenantId(principal);
        List<String> faculties = academicClassRepository.findDistinctFacultiesByInstitutionId(tenantId);
        List<Integer> semesters = List.of(1, 2, 3, 4, 5, 6, 7, 8);

        return StudentFilterOptionsResponse.builder()
                .faculties(faculties)
                .semesters(semesters)
                .build();
    }

    @Transactional
    public BulkTransferResponse bulkTransferStudents(Principal principal, BulkTransferRequest request) {
        Long tenantId = getTenantId(principal);

        if (request.getStudentIds() == null || request.getStudentIds().isEmpty()) {
            throw new BusinessRuleException("Student IDs list must not be empty.");
        }

        AcademicClass targetClass = academicClassRepository
                .findByClassIdAndInstitution_InstitutionId(request.getTargetClassId(), tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Target Academic Class not found for ID: " + request.getTargetClassId()));

        long validStudents = studentRepository.countByStudentIdInAndTenantId(request.getStudentIds(), tenantId);
        if (validStudents != request.getStudentIds().size()) {
            throw new TenantMismatchException("One or more selected students do not belong to your institution.");
        }

        int updatedCount = studentRepository.bulkUpdateAcademicClass(request.getStudentIds(), targetClass.getClassId(), tenantId);

        subjectEnrollmentRepository.bulkDeleteByStudentIds(request.getStudentIds());

        subjectEnrollmentRepository.bulkInsertEnrollmentsForTargetClass(
                request.getStudentIds(),
                tenantId,
                targetClass.getFaculty(),
                targetClass.getSemester()
        );

        log.info("Bulk transferred {} students to AcademicClass {} (Faculty: {}, Sem: {}) for tenant {}.",
                updatedCount, targetClass.getClassId(), targetClass.getFaculty(), targetClass.getSemester(), tenantId);

        return BulkTransferResponse.builder()
                .success(true)
                .updatedStudents(updatedCount)
                .targetClass(BulkTransferResponse.TargetClassDto.builder()
                        .classId(targetClass.getClassId())
                        .faculty(targetClass.getFaculty())
                        .semester(targetClass.getSemester())
                        .displayName(targetClass.getDisplayName())
                        .build())
                .build();
    }

    public void verifyTeacher(Long teacherId, String adminEmail) {
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new UserNotFoundException("Teacher not found with ID: " + teacherId));

        User user = teacher.getUser();
        if (UserStatus.ACTIVE.equals(user.getStatus())) {
            throw new TeacherAlreadyVerifiedException("Teacher is already verified.");
        }

        user.setStatus(UserStatus.ACTIVE);
        userRepository.save(user);

        verificationRepository.findByUser(user)
                .ifPresent(req -> {
                    req.setStatus(VerificationStatus.APPROVED);
                    verificationRepository.save(req);
                });

        log.info("Teacher ID: {} verified by Admin: {}.", teacherId, adminEmail);
    }

    public void rejectTeacher(Long teacherId, RejectTeacherRequest request, String adminEmail) {
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new UserNotFoundException("Teacher not found with ID: " + teacherId));

        User user = teacher.getUser();
        user.setStatus(UserStatus.SUSPENDED);
        userRepository.save(user);

        verificationRepository.findByUser(user)
                .ifPresent(req -> {
                    req.setStatus(VerificationStatus.REJECTED);
                    req.setRejectionReason(request.getRejectionReason());
                    verificationRepository.save(req);
                });

        log.info("Teacher ID: {} rejected by Admin: {}. Reason: {}", teacherId, adminEmail, request.getRejectionReason());
    }

    public void suspendUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));

        user.setStatus(UserStatus.SUSPENDED);
        userRepository.save(user);

        Instant suspendedAt = Instant.now();
        userTokenRevocationService.revokeUserTokens(userId, suspendedAt);

        log.info("User ID: {} suspended at {}.", userId, suspendedAt);
    }

    public void activateUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));

        user.setStatus(UserStatus.ACTIVE);
        userRepository.save(user);

        log.info("User ID: {} activated.", userId);
    }

    public void changeRole(Long userId, ChangeRoleRequest request, String adminEmail) {
        if (UserRole.SUPER_ADMIN.equals(request.getRole())) {
            throw new SecurityException("Cannot promote user to SUPER_ADMIN via admin role management.");
        }

        User targetUser = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));

        Long currentTenant = com.college.bridge.common.tenant.TenantContext.get();
        if (currentTenant != null && targetUser.getInstitution() != null 
                && !currentTenant.equals(targetUser.getInstitution().getInstitutionId())) {
            throw new TenantMismatchException("User does not belong to your institution.");
        }

        if (targetUser.getRole() == request.getRole()) {
            return;
        }

        if (UserRole.ADMIN.equals(targetUser.getRole()) && !UserRole.ADMIN.equals(request.getRole())) {
            long adminCount = userRepository.countByRoleAndStatus(UserRole.ADMIN, UserStatus.ACTIVE);
            if (adminCount <= 1) {
                throw new BusinessRuleException("Cannot change role. At least one active Administrator must exist.");
            }
        }

        UserRole oldRole = targetUser.getRole();
        targetUser.setRole(request.getRole());
        userRepository.save(targetUser);

        if (oldRole == UserRole.STUDENT) {
            studentRepository.findByUser(targetUser).ifPresent(studentRepository::delete);
        } else if (oldRole == UserRole.TEACHER) {
            teacherRepository.findByUser(targetUser).ifPresent(teacherRepository::delete);
        }

        if (request.getRole() == UserRole.TEACHER) {
            if (!teacherRepository.existsByUser(targetUser)) {
                teacherRepository.save(Teacher.builder().user(targetUser).build());
            }
        } else if (request.getRole() == UserRole.STUDENT) {
            throw new InvalidRoleException("Cannot change role to STUDENT. Students must enroll via the standard registration endpoint to establish enrollment links.");
        }

        refreshTokenRepository.revokeAllByUser(targetUser);
        log.info("User ID: {} role updated from {} to {} by admin: {}", userId, oldRole, request.getRole(), adminEmail);
    }

    public void deleteUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));

        if (UserRole.ADMIN.equals(user.getRole())) {
            long adminCount = userRepository.countByRoleAndStatus(UserRole.ADMIN, UserStatus.ACTIVE);
            if (adminCount <= 1) {
                throw new BusinessRuleException("Cannot delete the only remaining active Administrator.");
            }
        }

        refreshTokenRepository.revokeAllByUser(user);
        userRepository.delete(user);
        log.info("User ID: {} soft-deleted by Admin.", userId);
    }

    private Long getTenantId(Principal principal) {
        Long tenantId = com.college.bridge.common.tenant.TenantContext.get();
        if (tenantId != null) {
            return tenantId;
        }
        if (principal != null && principal.getName() != null) {
            User user = userRepository.findByEmail(principal.getName()).orElse(null);
            if (user != null && user.getInstitution() != null) {
                return user.getInstitution().getInstitutionId();
            }
        }
        throw new BusinessRuleException("Institution context is missing.");
    }
}
