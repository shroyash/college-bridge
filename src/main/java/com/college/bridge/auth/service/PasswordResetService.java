package com.college.bridge.auth.service;

import com.college.bridge.auth.dto.*;
import com.college.bridge.auth.entity.OtpType;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.repository.RefreshTokenRepository;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.common.tenant.TenantContext;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
@Slf4j
@Transactional
public class PasswordResetService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final OtpService otpService;

    public PasswordResetService(
            UserRepository userRepository,
            RefreshTokenRepository refreshTokenRepository,
            PasswordEncoder passwordEncoder,
            OtpService otpService) {
        this.userRepository = userRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.otpService = otpService;
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
                OtpType.PASSWORD_RESET);

        if (!isValidToken) {
            throw new BadCredentialsException("Invalid or expired password reset token.");
        }

        Long tenantId = TenantContext.get();
        User user;
        if (tenantId != null) {
            user = userRepository.findByInstitution_InstitutionIdAndEmail(tenantId, request.getEmail())
                    .orElseThrow(
                            () -> new ResourceNotFoundException("User not found with email: " + request.getEmail()));
        } else {
            user = userRepository.findByEmail(request.getEmail())
                    .orElseThrow(
                            () -> new ResourceNotFoundException("User not found with email: " + request.getEmail()));
        }

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        otpService.invalidateVerificationToken(request.getEmail(), request.getVerificationToken(), OtpType.PASSWORD_RESET);

        refreshTokenRepository.revokeAllByUser(user);
        log.info("Password reset successful and all sessions revoked for user: {}", request.getEmail());
    }
}
