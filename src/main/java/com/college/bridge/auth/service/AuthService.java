package com.college.bridge.auth.service;

import com.college.bridge.auth.dto.*;
import com.college.bridge.auth.entity.*;
import com.college.bridge.auth.repository.*;
import com.college.bridge.auth.security.CustomUserDetails;
import com.college.bridge.auth.security.JwtProperties;
import com.college.bridge.auth.security.JwtService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@Slf4j
@Transactional
public class AuthService {

    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final AdminRepository adminRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final JwtProperties jwtProperties;
    private final AuthenticationManager authenticationManager;

    public AuthService(
            UserRepository userRepository,
            StudentRepository studentRepository,
            TeacherRepository teacherRepository,
            AdminRepository adminRepository,
            RefreshTokenRepository refreshTokenRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService,
            JwtProperties jwtProperties,
            AuthenticationManager authenticationManager
    ) {
        this.userRepository = userRepository;
        this.studentRepository = studentRepository;
        this.teacherRepository = teacherRepository;
        this.adminRepository = adminRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.jwtProperties = jwtProperties;
        this.authenticationManager = authenticationManager;
    }

    /**
     * Registers a new user based on their specific role and profile attributes.
     */
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Email is already in use: " + request.getEmail());
        }

        // Create base user record
        User user = User.builder()
                .name(request.getName())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .role(request.getRole())
                .build();
        
        User savedUser = userRepository.save(user);

        // Assign role-specific profile details
        switch (request.getRole()) {
            case STUDENT -> {
                Student student = Student.builder()
                        .user(savedUser)
                        .rollNumber(request.getRollNumber())
                        .semester(request.getSemester())
                        .department(request.getDepartment())
                        .build();
                studentRepository.save(student);
            }
            case TEACHER -> {
                Teacher teacher = Teacher.builder()
                        .user(savedUser)
                        .department(request.getDepartment())
                        .subject(request.getSubject())
                        .build();
                teacherRepository.save(teacher);
            }
            case ADMIN -> {
                Admin admin = Admin.builder()
                        .user(savedUser)
                        .department(request.getDepartment())
                        .build();
                adminRepository.save(admin);
            }
            default -> throw new IllegalArgumentException("Unknown user role: " + request.getRole());
        }

        log.info("Successfully registered user {} with role {}", savedUser.getEmail(), savedUser.getRole());

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
     * Authenicates user credentials, producing standard token payloads.
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
     * Create a database-backed refresh token.
     */
    private RefreshToken createRefreshToken(User user) {
        // Expiration configured from JwtProperties
        LocalDateTime expiry = LocalDateTime.now().plusNanos(jwtProperties.getRefreshTokenExpiration() * 1_000_000L);
        
        RefreshToken refreshToken = RefreshToken.builder()
                .user(user)
                .token(jwtService.generateRefreshTokenString())
                .expiryDate(expiry)
                .revoked(false)
                .build();
        
        return refreshTokenRepository.save(refreshToken);
    }
}
