package com.college.bridge.auth.service;

import com.college.bridge.academic.entity.AcademicClass;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.entity.SubjectEnrollment;
import com.college.bridge.academic.repository.AcademicClassRepository;
import com.college.bridge.academic.repository.SubjectEnrollmentRepository;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.auth.dto.*;
import com.college.bridge.auth.entity.*;
import com.college.bridge.auth.exception.AccountSuspendedException;
import com.college.bridge.auth.repository.*;
import com.college.bridge.auth.security.CustomUserDetailsService;
import com.college.bridge.auth.security.JwtProperties;
import com.college.bridge.auth.security.JwtService;
import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.exception.*;
import com.college.bridge.common.tenant.TenantContext;
import com.college.bridge.institution.entity.Institution;
import com.college.bridge.institution.entity.InstitutionStatus;
import com.college.bridge.institution.repository.InstitutionRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@Slf4j
@Transactional
public class AuthService {

    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final AcademicClassRepository academicClassRepository;
    private final SubjectRepository subjectRepository;
    private final SubjectEnrollmentRepository subjectEnrollmentRepository;
    private final InstitutionRepository institutionRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final JwtProperties jwtProperties;
    private final CustomUserDetailsService userDetailsService;
    private final OtpService otpService;

    public AuthService(
            UserRepository userRepository,
            StudentRepository studentRepository,
            RefreshTokenRepository refreshTokenRepository,
            AcademicClassRepository academicClassRepository,
            SubjectRepository subjectRepository,
            SubjectEnrollmentRepository subjectEnrollmentRepository,
            InstitutionRepository institutionRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService,
            JwtProperties jwtProperties,
            CustomUserDetailsService userDetailsService,
            OtpService otpService
    ) {
        this.userRepository = userRepository;
        this.studentRepository = studentRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.academicClassRepository = academicClassRepository;
        this.subjectRepository = subjectRepository;
        this.subjectEnrollmentRepository = subjectEnrollmentRepository;
        this.institutionRepository = institutionRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.jwtProperties = jwtProperties;
        this.userDetailsService = userDetailsService;
        this.otpService = otpService;
    }

    public AuthResponse register(RegisterRequest request) {
        Institution institution = institutionRepository.findByCode(request.getInstitutionCode())
                .orElseThrow(() -> new ResourceNotFoundException("Institution not found with code: " + request.getInstitutionCode()));

        if (userRepository.existsByInstitution_InstitutionIdAndEmail(institution.getInstitutionId(), request.getEmail())) {
            throw new DuplicateResourceException("Email is already registered in institution " + request.getInstitutionCode() + ": " + request.getEmail());
        }

        AcademicClass academicClass = academicClassRepository
                .findByInstitution_InstitutionIdAndFacultyAndSemester(institution.getInstitutionId(), request.getFaculty(), request.getSemester())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "No academic class found for faculty " + request.getFaculty()
                                + " semester " + request.getSemester() + " in institution " + request.getInstitutionCode()
                ));

        User user = User.builder()
                .institution(institution)
                .name(request.getName())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .role(UserRole.STUDENT)
                .status(UserStatus.ACTIVE)
                .build();
        User savedUser = userRepository.save(user);

        // Create Student profile linked to the resolved academic class
        Student student = Student.builder()
                .user(savedUser)
                .academicClass(academicClass)
                .build();
        Student savedStudent = studentRepository.save(student);

        // Auto-enroll in all subjects for this faculty + semester in this institution
        List<Subject> subjects = subjectRepository.findByInstitution_InstitutionIdAndFacultyAndSemester(
                institution.getInstitutionId(), request.getFaculty(), request.getSemester());

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

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken.getToken())
                .name(savedUser.getName())
                .email(savedUser.getEmail())
                .role(savedUser.getRole().name())
                .build();
    }

    public AuthResponse login(LoginRequest request) {
        User user;
        if (request.getInstitutionCode() != null && !request.getInstitutionCode().trim().isEmpty()) {
            Institution institution = institutionRepository.findByCode(request.getInstitutionCode().trim())
                    .orElseThrow(() -> new BadCredentialsException("Invalid email or password."));
            user = userRepository.findByInstitution_InstitutionIdAndEmail(institution.getInstitutionId(), request.getEmail())
                    .orElseThrow(() -> new BadCredentialsException("Invalid email or password."));
        } else {
            user = userRepository.findByEmail(request.getEmail())
                    .orElseThrow(() -> new BadCredentialsException("Invalid email or password."));
        }

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new BadCredentialsException("Invalid email or password.");
        }

        // Enforce status checking in strict order
        if (user.getRole() == UserRole.SUPER_ADMIN) {
            if (user.getStatus() != UserStatus.ACTIVE) {
                throw new AccountSuspendedException("User account is suspended.");
            }
        } else {
            // Check institution status first
            Institution institution = user.getInstitution();
            if (institution == null || institution.getStatus() == InstitutionStatus.PENDING) {
                throw new InstitutionPendingException("Institution registration is awaiting approval.");
            } else if (institution.getStatus() == InstitutionStatus.REJECTED) {
                String reason = institution.getRejectionReason();
                String msg = "Institution registration was rejected." + (reason != null && !reason.isBlank() ? " Reason: " + reason : "");
                throw new InstitutionRejectedException(msg, reason);
            } else if (institution.getStatus() == InstitutionStatus.SUSPENDED) {
                throw new InstitutionSuspendedException("Institution is suspended. Please contact support.");
            } else if (institution.getStatus() != InstitutionStatus.ACTIVE) {
                throw new InstitutionSuspendedException("Institution status is invalid.");
            }

            // Only check user status after institution is ACTIVE
            if (user.getStatus() == UserStatus.PENDING_VERIFICATION) {
                throw new AccountPendingVerificationException("User account is awaiting verification.");
            } else if (user.getStatus() == UserStatus.SUSPENDED) {
                throw new AccountSuspendedException("User account is suspended.");
            } else if (user.getStatus() != UserStatus.ACTIVE) {
                throw new AccountSuspendedException("User account is not active.");
            }
        }

        UserPrincipal userDetails;
        if (user.getInstitution() != null) {
            userDetails = (UserPrincipal) userDetailsService.loadUserByInstitutionIdAndEmail(user.getInstitution().getInstitutionId(), user.getEmail());
        } else {
            userDetails = (UserPrincipal) userDetailsService.loadUserByUsername(user.getEmail());
        }

        String accessToken = jwtService.generateAccessToken(userDetails);
        RefreshToken refreshToken = createRefreshToken(user);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken.getToken())
                .name(user.getName())
                .email(user.getEmail())
                .role(user.getRole().name())
                .build();
    }

    public AuthResponse refreshToken(TokenRefreshRequest request) {
        String tokenStr = request.getRefreshToken();
        RefreshToken refreshToken = refreshTokenRepository.findByToken(tokenStr)
                .orElseThrow(() -> new IllegalArgumentException("Invalid refresh token."));

        User user = refreshToken.getUser();

        if (refreshToken.isRevoked()) {
            refreshTokenRepository.revokeAllByUser(user);
            throw new SecurityException("This refresh token has already been used and is revoked. All active sessions for this account are terminated for safety.");
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
                .expiryDate(LocalDateTime.now().plusNanos(jwtProperties.getRefreshTokenExpiration() * 1_000_000L))
                .revoked(false)
                .build();
        refreshTokenRepository.save(newRefreshToken);

        UserPrincipal userPrincipal = new UserPrincipal(user);
        String accessToken = jwtService.generateAccessToken(userPrincipal);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(newRefreshTokenStr)
                .name(user.getName())
                .email(user.getEmail())
                .role(user.getRole().name())
                .build();
    }

    public void logout(String refreshTokenStr) {
        if (refreshTokenStr == null || refreshTokenStr.trim().isEmpty()) {
            return;
        }

        refreshTokenRepository.findByToken(refreshTokenStr).ifPresent(token -> {
            token.setRevoked(true);
            refreshTokenRepository.save(token);
            log.info("User session revoked. Token deactivated.");
        });
    }

    private RefreshToken createRefreshToken(User user) {
        LocalDateTime expiry = LocalDateTime.now().plusNanos(jwtProperties.getRefreshTokenExpiration() * 1_000_000L);

        RefreshToken refreshToken = RefreshToken.builder()
                .user(user)
                .token(jwtService.generateRefreshTokenString())
                .expiryDate(expiry)
                .revoked(false)
                .build();

        return refreshTokenRepository.save(refreshToken);
    }

    public void forgotPassword(ForgotPasswordRequest request) {
        Long tenantId = TenantContext.get();
        Optional<User> userOpt;
        if (tenantId != null) {
            userOpt = userRepository.findByInstitution_InstitutionIdAndEmail(tenantId, request.getEmail());
        } else {
            userOpt = userRepository.findByEmail(request.getEmail());
        }

        if (userOpt.isPresent()) {
            otpService.sendOtp(request.getEmail(), OtpType.PASSWORD_RESET);
            log.info("Password reset OTP requested and sent for: {}", request.getEmail());
        } else {
            log.warn("Password reset requested for non-existent email: {}", request.getEmail());
        }
    }

    public OtpVerificationResponse verifyOtp(VerifyOtpRequest request) {
        String token = otpService.verifyOtp(request.getEmail(), request.getCode(), request.getType());
        return OtpVerificationResponse.builder()
                .verified(true)
                .verificationToken(token)
                .build();
    }

    public void resendOtp(ForgotPasswordRequest request) {
        Long tenantId = TenantContext.get();
        Optional<User> userOpt;
        if (tenantId != null) {
            userOpt = userRepository.findByInstitution_InstitutionIdAndEmail(tenantId, request.getEmail());
        } else {
            userOpt = userRepository.findByEmail(request.getEmail());
        }

        if (userOpt.isPresent()) {
            otpService.sendOtp(request.getEmail(), OtpType.PASSWORD_RESET);
            log.info("Verification OTP resent to: {}", request.getEmail());
        } else {
            log.warn("Resend OTP requested for non-existent email: {}", request.getEmail());
        }
    }

    public void resetPassword(ResetPasswordRequest request) {
        boolean isValidToken = otpService.validateVerificationToken(
                request.getEmail(),
                request.getVerificationToken(),
                OtpType.PASSWORD_RESET
        );

        if (!isValidToken) {
            throw new BadCredentialsException("Invalid or expired password reset token.");
        }

        Long tenantId = TenantContext.get();
        User user;
        if (tenantId != null) {
            user = userRepository.findByInstitution_InstitutionIdAndEmail(tenantId, request.getEmail())
                    .orElseThrow(() -> new ResourceNotFoundException("User not found with email: " + request.getEmail()));
        } else {
            user = userRepository.findByEmail(request.getEmail())
                    .orElseThrow(() -> new ResourceNotFoundException("User not found with email: " + request.getEmail()));
        }

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        refreshTokenRepository.revokeAllByUser(user);
        log.info("Password reset successful and all sessions revoked for user: {}", request.getEmail());
    }
}
