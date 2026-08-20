package com.college.bridge.auth.service;

import java.time.Instant;
import java.time.LocalDateTime;
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

import com.college.bridge.auth.dto.ChangeRoleRequest;
import com.college.bridge.auth.dto.RejectTeacherRequest;
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
import com.college.bridge.verification.entity.TeacherVerificationRequest;
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

        Map<Long, Student> students = studentByUserId;
        Map<Long, Teacher> teachers = teacherByUserId;

        return userPage.map(user -> userMapper.toProfileResponse(
                user,
                students.get(user.getUserId()),
                teachers.get(user.getUserId())
        ));
    }
    public void verifyTeacher(Long id, String adminEmail) {
        TeacherVerificationRequest request = verificationRepository.findById(id)
                .or(() -> userRepository.findById(id).flatMap(verificationRepository::findByUser))
                .orElseThrow(() -> new UserNotFoundException("Teacher verification request not found for ID: " + id));

        if (request.getStatus() != VerificationStatus.PENDING) {
            throw new TeacherAlreadyVerifiedException("Teacher verification request is already processed.");
        }

        User admin = userRepository.findByEmail(adminEmail)
                .orElseThrow(() -> new UserNotFoundException("Admin not found with email: " + adminEmail));

        request.setStatus(VerificationStatus.APPROVED);
        request.setReviewedBy(admin);
        request.setReviewedAt(LocalDateTime.now());
        verificationRepository.save(request);

        User applicant = request.getUser();
        studentRepository.findByUser(applicant).ifPresent(studentRepository::delete);

        applicant.setRole(UserRole.TEACHER);
        userRepository.save(applicant);

        if (!teacherRepository.existsByUser(applicant)) {
            Teacher teacher = Teacher.builder()
                    .user(applicant)
                    .build();
            teacherRepository.save(teacher);
        }

        refreshTokenRepository.revokeAllByUser(applicant);
        log.info("Teacher request ID: {} verified and upgraded successfully by admin: {}", id, adminEmail);
    }

    public void rejectTeacher(Long id, RejectTeacherRequest request, String adminEmail) {
        TeacherVerificationRequest verificationRequest = verificationRepository.findById(id)
                .or(() -> userRepository.findById(id).flatMap(verificationRepository::findByUser))
                .orElseThrow(() -> new UserNotFoundException("Teacher verification request not found for ID: " + id));

        if (verificationRequest.getStatus() != VerificationStatus.PENDING) {
            throw new TeacherAlreadyVerifiedException("Teacher verification request is already processed.");
        }

        User admin = userRepository.findByEmail(adminEmail)
                .orElseThrow(() -> new UserNotFoundException("Admin not found with email: " + adminEmail));

        verificationRequest.setStatus(VerificationStatus.REJECTED);
        verificationRequest.setRejectionReason(request != null ? request.getRejectionReason() : null);
        verificationRequest.setReviewedBy(admin);
        verificationRequest.setReviewedAt(LocalDateTime.now());
        verificationRepository.save(verificationRequest);

        log.info("Teacher request ID: {} rejected with reason: {} by admin: {}", id, request != null ? request.getRejectionReason() : null, adminEmail);
    }

    public void suspendUser(Long userId) {

        User user = userRepository.findById(userId)
                .orElseThrow(() ->
                        new UserNotFoundException(
                                "User not found with ID: " + userId
                        ));

        if (UserRole.ADMIN.equals(user.getRole())) {

            long adminCount =
                    userRepository.countByRoleAndStatus(
                            UserRole.ADMIN,
                            UserStatus.ACTIVE
                    );

            if (adminCount <= 1) {
                throw new BusinessRuleException(
                        "Cannot suspend the only remaining active Administrator."
                );
            }
        }

        Instant suspendedAt = Instant.now();

        user.setStatus(UserStatus.SUSPENDED);
        userRepository.save(user);

        refreshTokenRepository.revokeAllByUser(user);

        userTokenRevocationService.revokeUserTokens(
                userId,
                suspendedAt
        );

        log.info(
                "User ID: {} suspended at {}.",
                userId,
                suspendedAt
        );
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
            throw new com.college.bridge.common.exception.TenantMismatchException("User does not belong to your institution.");
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
}
