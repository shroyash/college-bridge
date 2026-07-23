package com.college.bridge.auth.service;

import java.time.LocalDateTime;

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
        Specification<User> spec = Specification.where(UserSpecification.hasRole(role))
                .and(UserSpecification.hasStatus(status));
        return userRepository.findAll(spec, pageable)
                .map(user -> {
                    Student student = null;
                    if (UserRole.STUDENT.equals(user.getRole())) {
                        student = studentRepository.findByUser(user).orElse(null);
                    }
                    return userMapper.toProfileResponse(user, student);
                });
    }

    public void verifyTeacher(Long requestId, String adminEmail) {
        TeacherVerificationRequest request = verificationRepository.findById(requestId)
                .orElseThrow(() -> new UserNotFoundException("Teacher verification request not found with ID: " + requestId));

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
        log.info("Teacher request ID: {} verified and upgraded successfully by admin: {}", requestId, adminEmail);
    }

    public void rejectTeacher(Long requestId, RejectTeacherRequest request, String adminEmail) {
        TeacherVerificationRequest verificationRequest = verificationRepository.findById(requestId)
                .orElseThrow(() -> new UserNotFoundException("Teacher verification request not found with ID: " + requestId));

        if (verificationRequest.getStatus() != VerificationStatus.PENDING) {
            throw new TeacherAlreadyVerifiedException("Teacher verification request is already processed.");
        }

        User admin = userRepository.findByEmail(adminEmail)
                .orElseThrow(() -> new UserNotFoundException("Admin not found with email: " + adminEmail));

        verificationRequest.setStatus(VerificationStatus.REJECTED);
        verificationRequest.setRejectionReason(request.getRejectionReason());
        verificationRequest.setReviewedBy(admin);
        verificationRequest.setReviewedAt(LocalDateTime.now());
        verificationRepository.save(verificationRequest);

        log.info("Teacher request ID: {} rejected with reason: {} by admin: {}", requestId, request.getRejectionReason(), adminEmail);
    }

    public void suspendUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));

        if (UserRole.ADMIN.equals(user.getRole())) {
            long adminCount = userRepository.countByRoleAndStatus(UserRole.ADMIN, UserStatus.ACTIVE);
            if (adminCount <= 1) {
                throw new BusinessRuleException("Cannot suspend the only remaining active Administrator.");
            }
        }

        user.setStatus(UserStatus.SUSPENDED);
        userRepository.save(user);

        refreshTokenRepository.revokeAllByUser(user);
        log.info("User ID: {} suspended.", userId);
    }

    public void activateUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));

        user.setStatus(UserStatus.ACTIVE);
        userRepository.save(user);

        log.info("User ID: {} activated.", userId);
    }

    public void changeRole(Long userId, ChangeRoleRequest request, String adminEmail) {
        User targetUser = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));

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
