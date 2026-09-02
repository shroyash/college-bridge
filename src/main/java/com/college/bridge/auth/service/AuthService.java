package com.college.bridge.auth.service;

import com.college.bridge.academic.entity.AcademicLevel;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.entity.SubjectEnrollment;
import com.college.bridge.academic.repository.AcademicLevelRepository;
import com.college.bridge.academic.repository.SubjectEnrollmentRepository;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.auth.dto.*;
import com.college.bridge.auth.entity.*;
import com.college.bridge.auth.exception.*;
import com.college.bridge.auth.repository.RefreshTokenRepository;
import com.college.bridge.auth.repository.StudentRepository;
import com.college.bridge.auth.repository.TeacherRepository;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.auth.security.CustomUserDetailsService;
import com.college.bridge.auth.security.JwtProperties;
import com.college.bridge.auth.security.JwtService;
import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.exception.*;
import com.college.bridge.common.exception.DuplicateResourceException;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.institution.entity.Institution;
import com.college.bridge.institution.entity.InstitutionStatus;
import com.college.bridge.institution.repository.InstitutionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class AuthService {

    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final AcademicLevelRepository academicLevelRepository;
    private final SubjectRepository subjectRepository;
    private final SubjectEnrollmentRepository subjectEnrollmentRepository;
    private final InstitutionRepository institutionRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final JwtProperties jwtProperties;
    private final CustomUserDetailsService userDetailsService;
    private final AuthenticationManager authenticationManager;

    public AuthResponse register(RegisterRequest request) {

        Institution institution = institutionRepository.findByCode(request.getInstitutionCode())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Institution not found with code: " + request.getInstitutionCode()));

        if (userRepository.existsByInstitution_InstitutionIdAndEmail(institution.getInstitutionId(),
                request.getEmail())) {
            throw new DuplicateResourceException("Email is already registered in institution "
                    + request.getInstitutionCode() + ": " + request.getEmail());
        }

        AcademicLevel academicLevel = academicLevelRepository
                .findByLevelIdAndProgram_Institution_InstitutionIdAndDeletedFalseAndProgram_DeletedFalse(request.getLevelId(), institution.getInstitutionId())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "No academic level found with ID " + request.getLevelId()
                                + " in institution " + request.getInstitutionCode()));

        User user = User.builder()
                .institution(institution)
                .name(request.getName())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .role(UserRole.STUDENT)
                .status(UserStatus.ACTIVE)
                .build();
        User savedUser = userRepository.save(user);

        Student student = Student.builder()
                .user(savedUser)
                .academicLevel(academicLevel)
                .build();
        Student savedStudent = studentRepository.save(student);

        // Auto-enroll in all subjects for this level
        List<Subject> subjects = subjectRepository.findByAcademicLevel_LevelIdAndDeletedFalse(academicLevel.getLevelId());

        List<SubjectEnrollment> enrollments = subjects.stream()
                .map(subject -> SubjectEnrollment.builder()
                        .student(savedStudent)
                        .subject(subject)
                        .build())
                .toList();
        subjectEnrollmentRepository.saveAll(enrollments);

        // Issue tokens
        UserPrincipal userPrincipal = new UserPrincipal(savedUser, savedStudent.getStudentId(), null);
        String accessToken = jwtService.generateAccessToken(userPrincipal);
        RefreshToken refreshToken = createRefreshToken(savedUser);

        InstitutionInfoResponse instResponse = InstitutionInfoResponse.builder()
                .institutionId(institution.getInstitutionId())
                .name(institution.getName())
                .code(institution.getCode())
                .build();

        UserInfoResponse userResponse = UserInfoResponse.builder()
                .userId(savedUser.getUserId())
                .name(savedUser.getName())
                .email(savedUser.getEmail())
                .role(savedUser.getRole().name())
                .institution(instResponse)
                .build();

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken.getToken())
                .user(userResponse)
                .build();
    }

    public AuthResponse login(LoginRequest request) {

        String email = request.getEmail().trim().toLowerCase();

        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(email, request.getPassword()));

        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        User user = userRepository.findById(userPrincipal.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        validateAccountStatus(user);

        String accessToken = jwtService.generateAccessToken(userPrincipal);

        refreshTokenRepository.revokeAllByUser(user);

        RefreshToken refreshToken = createRefreshToken(user);

        Institution inst = user.getInstitution();
        InstitutionInfoResponse instResponse = inst != null ? InstitutionInfoResponse.builder()
                .institutionId(inst.getInstitutionId())
                .name(inst.getName())
                .code(inst.getCode())
                .build() : null;

        UserInfoResponse userResponse = UserInfoResponse.builder()
                .userId(user.getUserId())
                .name(user.getName())
                .email(user.getEmail())
                .role(user.getRole().name())
                .institution(instResponse)
                .build();

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken.getToken())
                .user(userResponse)
                .build();
    }

    private void validateAccountStatus(User user) {
        if (user.getRole() == UserRole.SUPER_ADMIN) {
            if (user.getStatus() != UserStatus.ACTIVE) {
                throw new AccountSuspendedException("User account is suspended.");
            }
        } else {
            Institution institution = user.getInstitution();
            if (institution == null || institution.getStatus() == InstitutionStatus.PENDING) {
                throw new InstitutionPendingException("Institution registration is awaiting approval.");
            } else if (institution.getStatus() == InstitutionStatus.REJECTED) {
                String reason = institution.getRejectionReason();
                String msg = "Institution registration was rejected."
                        + (reason != null && !reason.isBlank() ? " Reason: " + reason : "");
                throw new InstitutionRejectedException(msg, reason);
            } else if (institution.getStatus() == InstitutionStatus.SUSPENDED) {
                throw new InstitutionSuspendedException("Institution is suspended. Please contact support.");
            } else if (institution.getStatus() != InstitutionStatus.ACTIVE) {
                throw new InstitutionSuspendedException("Institution status is invalid.");
            }

            if (user.getStatus() == UserStatus.PENDING_VERIFICATION) {
                throw new AccountPendingVerificationException("User account is awaiting verification.");
            } else if (user.getStatus() == UserStatus.SUSPENDED) {
                throw new AccountSuspendedException("User account is suspended.");
            } else if (user.getStatus() != UserStatus.ACTIVE) {
                throw new AccountSuspendedException("User account is not active.");
            }
        }
    }

    public AuthResponse refreshToken(TokenRefreshRequest request) {
        String tokenStr = request.getRefreshToken();
        RefreshToken refreshToken = refreshTokenRepository.findByToken(tokenStr)
                .orElseThrow(() -> new IllegalArgumentException("Invalid refresh token."));

        User user = refreshToken.getUser();

        if (refreshToken.isRevoked()) {
            refreshTokenRepository.revokeAllByUser(user);
            throw new SecurityException(
                    "This refresh token has already been used and is revoked. All active sessions for this account are terminated for safety.");
        }

        if (refreshToken.isExpired()) {
            refreshToken.setRevoked(true);
            refreshTokenRepository.save(refreshToken);
            throw new IllegalArgumentException("Refresh token has expired. Please login again.");
        }

        refreshToken.setRevoked(true);
        String newRefreshTokenStr = jwtService.generateRefreshTokenString();
        refreshToken.setReplacedByToken(newRefreshTokenStr);
        refreshTokenRepository.save(refreshToken);

        RefreshToken newRefreshToken = RefreshToken.builder()
                .user(user)
                .token(newRefreshTokenStr)
                .expiryDate(LocalDateTime.now().plus(jwtProperties.getRefreshTokenExpiration()))
                .revoked(false)
                .build();
        refreshTokenRepository.save(newRefreshToken);

        UserPrincipal userPrincipal = userDetailsService.buildUserPrincipal(user);
        String accessToken = jwtService.generateAccessToken(userPrincipal);

        Institution inst = user.getInstitution();
        InstitutionInfoResponse instResponse = inst != null ? InstitutionInfoResponse.builder()
                .institutionId(inst.getInstitutionId())
                .name(inst.getName())
                .code(inst.getCode())
                .build() : null;

        UserInfoResponse userResponse = UserInfoResponse.builder()
                .userId(user.getUserId())
                .name(user.getName())
                .email(user.getEmail())
                .role(user.getRole().name())
                .institution(instResponse)
                .build();

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(newRefreshToken.getToken())
                .user(userResponse)
                .build();
    }

    public void logout(String refreshTokenStr) {
        if (refreshTokenStr != null && !refreshTokenStr.isBlank()) {
            refreshTokenRepository.findByToken(refreshTokenStr).ifPresent(rt -> {
                rt.setRevoked(true);
                refreshTokenRepository.save(rt);
            });
        }
    }

    private RefreshToken createRefreshToken(User user) {
        RefreshToken refreshToken = RefreshToken.builder()
                .user(user)
                .token(jwtService.generateRefreshTokenString())
                .expiryDate(LocalDateTime.now().plus(jwtProperties.getRefreshTokenExpiration()))
                .revoked(false)
                .build();
        return refreshTokenRepository.save(refreshToken);
    }
}
