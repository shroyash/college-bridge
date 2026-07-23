package com.college.bridge.auth.service;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import com.college.bridge.auth.dto.ChangePasswordRequest;
import com.college.bridge.auth.dto.ConfirmEmailChangeRequest;
import com.college.bridge.auth.dto.InitiateEmailChangeRequest;
import com.college.bridge.auth.dto.UpdateProfileRequest;
import com.college.bridge.auth.dto.UserProfileResponse;
import com.college.bridge.auth.entity.OtpType;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.exception.EmailAlreadyExistsException;
import com.college.bridge.auth.exception.InvalidPasswordException;
import com.college.bridge.auth.exception.UserNotFoundException;
import com.college.bridge.auth.mapper.UserMapper;
import com.college.bridge.auth.repository.RefreshTokenRepository;
import com.college.bridge.auth.repository.StudentRepository;
import com.college.bridge.auth.repository.UserRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class AccountService {

    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final FileStorageService fileStorageService;
    private final OtpService otpService;
    private final PasswordEncoder passwordEncoder;
    private final UserMapper userMapper;

    @Transactional(readOnly = true)
    public UserProfileResponse getProfile(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UserNotFoundException("User not found with email: " + email));

        Student student = null;
        if (com.college.bridge.auth.entity.UserRole.STUDENT.equals(user.getRole())) {
            student = studentRepository.findByUser(user).orElse(null);
        }

        return userMapper.toProfileResponse(user, student);
    }

    public UserProfileResponse updateProfile(String email, UpdateProfileRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UserNotFoundException("User not found with email: " + email));

        user.setName(request.getName());
        if (request.getFcmToken() != null) {
            user.setFcmToken(request.getFcmToken());
        }

        User updatedUser = userRepository.save(user);

        Student student = null;
        if (com.college.bridge.auth.entity.UserRole.STUDENT.equals(updatedUser.getRole())) {
            student = studentRepository.findByUser(updatedUser).orElse(null);
        }

        log.info("Profile updated for user: {}", email);
        return userMapper.toProfileResponse(updatedUser, student);
    }

    public void changePassword(String email, ChangePasswordRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UserNotFoundException("User not found with email: " + email));

        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPasswordHash())) {
            throw new InvalidPasswordException("Current password does not match.");
        }

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        refreshTokenRepository.revokeAllByUser(user);
        log.info("Password changed and active sessions revoked for user: {}", email);
    }

    public void initiateEmailChange(String currentEmail, InitiateEmailChangeRequest request) {
        if (userRepository.existsByEmail(request.getNewEmail())) {
            throw new EmailAlreadyExistsException("The new email is already registered.");
        }

        otpService.sendOtp(request.getNewEmail(), OtpType.EMAIL_CHANGE);
        log.info("Initiated email change. OTP sent to: {}", request.getNewEmail());
    }

    public void confirmEmailChange(String currentEmail, ConfirmEmailChangeRequest request) {
        User user = userRepository.findByEmail(currentEmail)
                .orElseThrow(() -> new UserNotFoundException("User not found with email: " + currentEmail));

        if (userRepository.existsByEmail(request.getNewEmail())) {
            throw new EmailAlreadyExistsException("The new email is already registered.");
        }

        otpService.verifyOtp(request.getNewEmail(), request.getCode(), OtpType.EMAIL_CHANGE);

        user.setEmail(request.getNewEmail());
        userRepository.save(user);

        refreshTokenRepository.revokeAllByUser(user);
        log.info("Email updated from {} to {}", currentEmail, request.getNewEmail());
    }

    public String uploadProfileImage(String email, MultipartFile file) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UserNotFoundException("User not found with email: " + email));

        String imageUrl = fileStorageService.storeFile(file);
        user.setImageUrl(imageUrl);
        userRepository.save(user);

        log.info("Profile image uploaded for user: {}. URL: {}", email, imageUrl);
        return imageUrl;
    }

    public void deleteOwnAccount(String email, String password) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UserNotFoundException("User not found with email: " + email));

        if (!passwordEncoder.matches(password, user.getPasswordHash())) {
            throw new InvalidPasswordException("Password verification failed. Cannot delete account.");
        }

        refreshTokenRepository.revokeAllByUser(user);

        userRepository.delete(user);
        log.info("Account soft-deleted: {}", email);
    }
}
