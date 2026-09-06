package com.college.bridge.auth.service;

import com.college.bridge.auth.dto.*;
import com.college.bridge.auth.entity.OtpType;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.repository.RefreshTokenRepository;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.common.exception.ResourceNotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;

@Service
@Slf4j
@Transactional
public class PasswordResetService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final OtpService otpService;
    private final TokenRevocationService userTokenRevocationService;

    public PasswordResetService(
            UserRepository userRepository,
            RefreshTokenRepository refreshTokenRepository,
            PasswordEncoder passwordEncoder,
            OtpService otpService,
            TokenRevocationService userTokenRevocationService) {
        this.userRepository = userRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.otpService = otpService;
        this.userTokenRevocationService = userTokenRevocationService;
    }

    public void forgotPassword(ForgotPasswordRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        Optional<User> userOpt = userRepository.findByEmail(email);

        if (userOpt.isPresent()) {
            otpService.sendOtp(email, OtpType.PASSWORD_RESET);
        } else {
            log.warn("Password reset requested for non-existent email: {}", email);
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
        String email = request.getEmail().trim().toLowerCase();
        Optional<User> userOpt = userRepository.findByEmail(email);

        if (userOpt.isPresent()) {
            otpService.sendOtp(email, OtpType.PASSWORD_RESET);
        } else {
            log.warn("Resend OTP requested for non-existent email: {}", email);
        }
    }

    public void resetPassword(ResetPasswordRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        boolean isValidToken = otpService.validateVerificationToken(
                email,
                request.getVerificationToken(),
                OtpType.PASSWORD_RESET);

        if (!isValidToken) {
            throw new BadCredentialsException("Invalid or expired password reset token.");
        }

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with email: " + email));

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        otpService.invalidateVerificationToken(email, request.getVerificationToken(), OtpType.PASSWORD_RESET);

        refreshTokenRepository.revokeAllByUser(user);
        userTokenRevocationService.revokeUserTokens(user.getUserId(), Instant.now());
    }
}
