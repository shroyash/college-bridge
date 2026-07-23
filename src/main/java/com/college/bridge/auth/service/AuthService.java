package com.college.bridge.auth.service;

import com.college.bridge.academic.entity.AcademicClass;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.entity.SubjectEnrollment;
import com.college.bridge.academic.repository.AcademicClassRepository;
import com.college.bridge.academic.repository.SubjectEnrollmentRepository;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.auth.dto.*;
import com.college.bridge.auth.entity.*;
import com.college.bridge.auth.repository.*;
import com.college.bridge.auth.security.CustomUserDetails;
import com.college.bridge.auth.security.JwtProperties;
import com.college.bridge.auth.security.JwtService;
import com.college.bridge.common.exception.DuplicateResourceException;
import com.college.bridge.common.exception.ResourceNotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
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
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final JwtProperties jwtProperties;
    private final AuthenticationManager authenticationManager;
    private final OtpService otpService;

    public AuthService(
            UserRepository userRepository,
            StudentRepository studentRepository,
            RefreshTokenRepository refreshTokenRepository,
            AcademicClassRepository academicClassRepository,
            SubjectRepository subjectRepository,
            SubjectEnrollmentRepository subjectEnrollmentRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService,
            JwtProperties jwtProperties,
            AuthenticationManager authenticationManager,
            OtpService otpService
    ) {
        this.userRepository = userRepository;
        this.studentRepository = studentRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.academicClassRepository = academicClassRepository;
        this.subjectRepository = subjectRepository;
        this.subjectEnrollmentRepository = subjectEnrollmentRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.jwtProperties = jwtProperties;
        this.authenticationManager = authenticationManager;
        this.otpService = otpService;
    }

    /**
     * Registers a new user as ROLE_STUDENT.
     * <p>
     * The backend exclusively assigns the student role — the frontend never
     * sends a role field. After registration the student is automatically:
     * <ul>
     *   <li>Linked to the correct {@link AcademicClass} for their faculty+semester</li>
     *   <li>Enrolled in every {@link Subject} belonging to that class</li>
     * </ul>
     */
    public AuthResponse register(RegisterRequest request) {
        // Duplicate email guard
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new DuplicateResourceException("Email is already registered: " + request.getEmail());
        }

        // Resolve the academic class — must exist (seeded by AcademicDataInitializer)
        AcademicClass academicClass = academicClassRepository
                .findByFacultyAndSemester(request.getFaculty(), request.getSemester())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "No academic class found for faculty " + request.getFaculty()
                        + " semester " + request.getSemester()
                ));

        // Create base User — role is ALWAYS STUDENT here
        User user = User.builder()
                .name(request.getName())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .role(UserRole.STUDENT)
                .build();
        User savedUser = userRepository.save(user);

        // Create Student profile linked to the resolved academic class
        Student student = Student.builder()
                .user(savedUser)
                .academicClass(academicClass)
                .build();
        Student savedStudent = studentRepository.save(student);

        // Auto-enroll in all subjects for this faculty + semester
        List<Subject> subjects = subjectRepository.findByFacultyAndSemester(
                request.getFaculty(), request.getSemester());

        List<SubjectEnrollment> enrollments = subjects.stream()
                .map(subject -> SubjectEnrollment.builder()
                        .student(savedStudent)
                        .subject(subject)
                        .build())
                .toList();
        subjectEnrollmentRepository.saveAll(enrollments);

        log.info("Registered student {} in {} Semester {} with {} subject enrollments.",
                savedUser.getEmail(), request.getFaculty(), request.getSemester(), enrollments.size());

        // Issue tokens
        CustomUserDetails userDetails = new CustomUserDetails(savedUser);
        String accessToken = jwtService.generateAccessToken(userDetails);
        RefreshToken refreshToken = createRefreshToken(savedUser);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken.getToken())
                .name(savedUser.getName())
                .email(savedUser.getEmail())
                .role(savedUser.getRole().name())
                .build();
    }

    /**
     * Authenticates user credentials, producing standard token payloads.
     */
    public AuthResponse login(LoginRequest request) {
        log.info("Processing login request for user: {}", request.getEmail());

        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
        );

        CustomUserDetails userDetails = (CustomUserDetails) authentication.getPrincipal();
        User user = userDetails.getUser();

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

    /**
     * Decouples token rotation logic. Verifies refresh token state.
     * Prevents replay attacks (refresh token stealing) via RTR.
     */
    public AuthResponse refreshToken(TokenRefreshRequest request) {
        String tokenStr = request.getRefreshToken();
        RefreshToken refreshToken = refreshTokenRepository.findByToken(tokenStr)
                .orElseThrow(() -> new IllegalArgumentException("Invalid refresh token."));

        User user = refreshToken.getUser();

        // RTR Detection: Token was previously revoked/rotated. Treat as a security breach!
        if (refreshToken.isRevoked()) {
            refreshTokenRepository.revokeAllByUser(user);
            log.warn("Potential Token Replay Attack Detected: User {} used a revoked refresh token. All active sessions closed.", user.getEmail());
            throw new SecurityException("This refresh token has already been used and is revoked. All active sessions for this account are terminated for safety.");
        }

        // Expiry check
        if (refreshToken.isExpired()) {
            refreshToken.setRevoked(true);
            refreshTokenRepository.save(refreshToken);
            throw new IllegalArgumentException("Refresh token has expired. Please login again.");
        }

        // Setup token rotation (Old token gets marked revoked and replaced)
        refreshToken.setRevoked(true);
        String newRefreshTokenStr = jwtService.generateRefreshTokenString();
        refreshToken.setReplacedByToken(newRefreshTokenStr);
        refreshTokenRepository.save(refreshToken);

        // Save new active Session Token
        RefreshToken newRefreshToken = RefreshToken.builder()
                .user(user)
                .token(newRefreshTokenStr)
                .expiryDate(LocalDateTime.now().plusNanos(jwtProperties.getRefreshTokenExpiration() * 1_000_000L))
                .revoked(false)
                .build();
        refreshTokenRepository.save(newRefreshToken);

        CustomUserDetails userDetails = new CustomUserDetails(user);
        String accessToken = jwtService.generateAccessToken(userDetails);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(newRefreshTokenStr)
                .name(user.getName())
                .email(user.getEmail())
                .role(user.getRole().name())
                .build();
    }

    /**
     * Revokes the active refresh token upon logging out.
     */
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

    /**
     * Creates a database-backed refresh token.
     */
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
        // Safe check to prevent user enumeration
        Optional<User> userOpt = userRepository.findByEmail(request.getEmail());
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
        // Enforce same safety constraints as forgotPassword
        Optional<User> userOpt = userRepository.findByEmail(request.getEmail());
        if (userOpt.isPresent()) {
            otpService.sendOtp(request.getEmail(), OtpType.PASSWORD_RESET);
            log.info("Verification OTP resent to: {}", request.getEmail());
        } else {
            log.warn("Resend OTP requested for non-existent email: {}", request.getEmail());
        }
    }

    public void resetPassword(ResetPasswordRequest request) {
        // Check verification token validity
        boolean isValidToken = otpService.validateVerificationToken(
                request.getEmail(), 
                request.getVerificationToken(), 
                OtpType.PASSWORD_RESET
        );

        if (!isValidToken) {
            throw new org.springframework.security.authentication.BadCredentialsException("Invalid or expired password reset token.");
        }

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new ResourceNotFoundException("User not found with email: " + request.getEmail()));

        // Encode and update password
        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        // Security: Revoke tokens on password change
        refreshTokenRepository.revokeAllByUser(user);
        log.info("Password reset successful and all sessions revoked for user: {}", request.getEmail());
    }
}

