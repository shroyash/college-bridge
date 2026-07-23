package com.college.bridge.auth.service;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;

import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.college.bridge.auth.entity.OneTimePassword;
import com.college.bridge.auth.entity.OtpType;
import com.college.bridge.auth.exception.OtpExpiredException;
import com.college.bridge.auth.exception.OtpInvalidException;
import com.college.bridge.auth.repository.OneTimePasswordRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class OtpService {

    private final OneTimePasswordRepository otpRepository;
    private final JavaMailSender mailSender;
    private final SecureRandom secureRandom = new SecureRandom();

    public void sendOtp(String email, OtpType type) {
        Optional<OneTimePassword> existingOtpOpt = otpRepository
                .findFirstByEmailAndTypeAndVerifiedOrderByCreatedAtDesc(email, type, false);

        if (existingOtpOpt.isPresent()) {
            OneTimePassword existing = existingOtpOpt.get();
            if (existing.getCreatedAt().plusSeconds(60).isAfter(LocalDateTime.now())) {
                throw new IllegalArgumentException("Please wait at least 60 seconds before requesting a new OTP.");
            }
            existing.setVerified(true);
            otpRepository.save(existing);
        }

        String code = String.format("%06d", secureRandom.nextInt(1000000));
        LocalDateTime expiry = LocalDateTime.now().plusMinutes(5);

        OneTimePassword otp = OneTimePassword.builder()
                .email(email)
                .code(code)
                .type(type)
                .expiryDate(expiry)
                .verified(false)
                .build();

        otpRepository.save(otp);

        log.info("Generated OTP {} for email {} and type {}", code, email, type);

        CompletableFuture.runAsync(() -> {
            try {
                SimpleMailMessage message = new SimpleMailMessage();
                message.setTo(email);
                message.setSubject("College Bridge OTP Verification");
                message.setText("Dear User,\n\nYour One Time Password (OTP) for verification is: " + code
                        + "\n\nThis OTP is valid for 5 minutes only.\n\nWarm regards,\nCollege Bridge Team");
                mailSender.send(message);
                log.info("OTP Email sent successfully to {}", email);
            } catch (Exception ex) {
                log.warn("Could not send SMTP email to {}. If Google Mail credentials are not set up yet, find your OTP code here in logs: OTP = {}", email, code, ex);
            }
        });
    }

    public String verifyOtp(String email, String code, OtpType type) {
        OneTimePassword otp = otpRepository
                .findFirstByEmailAndTypeAndVerifiedOrderByCreatedAtDesc(email, type, false)
                .orElseThrow(() -> new OtpInvalidException("No pending OTP found for this email."));

        if (otp.getAttempts() >= 5) {
            otp.setVerified(true);
            otpRepository.save(otp);
            throw new OtpExpiredException("Too many invalid verification attempts. OTP has been invalidated. Please request a new one.");
        }

        if (otp.isExpired()) {
            otp.setVerified(true);
            otpRepository.save(otp);
            throw new OtpExpiredException("The OTP code has expired. Please request a new one.");
        }

        if (!otp.getCode().equals(code)) {
            otp.setAttempts(otp.getAttempts() + 1);
            otpRepository.save(otp);
            throw new OtpInvalidException("Invalid OTP code. Remaining attempts: " + (5 - otp.getAttempts()));
        }

        String token = UUID.randomUUID().toString();
        otp.setVerified(true);
        otp.setVerificationToken(token);
        otpRepository.save(otp);

        log.info("OTP verified successfully for email {}. Verification token: {}", email, token);
        return token;
    }

    public boolean validateVerificationToken(String email, String token, OtpType type) {
        if (token == null || token.isBlank()) {
            return false;
        }

        return otpRepository.findFirstByEmailAndTypeAndVerifiedOrderByCreatedAtDesc(email, type, true)
                .map(otp -> token.equals(otp.getVerificationToken())
                        && otp.getCreatedAt().plusMinutes(15).isAfter(LocalDateTime.now()))
                .orElse(false);
    }
}
