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
import com.college.bridge.auth.entity.UserRole;
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


    private User findUser(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() ->
                        new UserNotFoundException(
                                "User not found with id: " + userId
                        )
                );
    }


    @Transactional(readOnly = true)
    public UserProfileResponse getProfile(Long userId) {

        User user = findUser(userId);

        Student student = null;

        if (user.getRole() == UserRole.STUDENT) {
            student = studentRepository.findByUser(user)
                    .orElse(null);
        }

        return userMapper.toProfileResponse(user, student);
    }


    public UserProfileResponse updateProfile(
            Long userId,
            UpdateProfileRequest request) {

        User user = findUser(userId);

        user.setName(request.getName());

        if (request.getFcmToken() != null) {
            user.setFcmToken(request.getFcmToken());
        }

        User updatedUser = userRepository.save(user);

        Student student = null;

        if (updatedUser.getRole() == UserRole.STUDENT) {
            student = studentRepository.findByUser(updatedUser)
                    .orElse(null);
        }

        return userMapper.toProfileResponse(
                updatedUser,
                student
        );
    }


    public void changePassword(
            Long userId,
            ChangePasswordRequest request) {

        User user = findUser(userId);

        if (!passwordEncoder.matches(
                request.getCurrentPassword(),
                user.getPasswordHash())) {

            throw new InvalidPasswordException(
                    "Current password does not match."
            );
        }

        user.setPasswordHash(
                passwordEncoder.encode(
                        request.getNewPassword()
                )
        );

        userRepository.save(user);

        refreshTokenRepository.revokeAllByUser(user);
    }


    public void initiateEmailChange(
            Long userId,
            InitiateEmailChangeRequest request) {

        User user = findUser(userId);

        if (!passwordEncoder.matches(
                request.getCurrentPassword(),
                user.getPasswordHash())) {

            throw new InvalidPasswordException(
                    "Current password does not match."
            );
        }

        if (userRepository.existsByEmail(request.getNewEmail())) {
            throw new EmailAlreadyExistsException(
                    "The new email is already registered."
            );
        }

        otpService.sendOtp(
                request.getNewEmail(),
                OtpType.EMAIL_CHANGE
        );

        log.info(
                "Email change initiated for userId={}",
                userId
        );
    }


    public void confirmEmailChange(
            Long userId,
            ConfirmEmailChangeRequest request) {

        User user = findUser(userId);

        if (userRepository.existsByEmail(request.getNewEmail())) {
            throw new EmailAlreadyExistsException(
                    "The new email is already registered."
            );
        }

        otpService.verifyOtp(
                request.getNewEmail(),
                request.getCode(),
                OtpType.EMAIL_CHANGE
        );

        String oldEmail = user.getEmail();

        user.setEmail(request.getNewEmail());

        userRepository.save(user);

        refreshTokenRepository.revokeAllByUser(user);

        log.info(
                "Email updated for userId={} from {}",
                userId,
                oldEmail
        );
    }


    public String uploadProfileImage(
            Long userId,
            MultipartFile file) {

        User user = findUser(userId);

        String imageUrl =
                fileStorageService.storeFile(file);

        user.setImageUrl(imageUrl);

        userRepository.save(user);

        log.info(
                "Profile image uploaded for userId={}",
                userId
        );

        return imageUrl;
    }


    public void deleteOwnAccount(
            Long userId,
            String password) {

        User user = findUser(userId);

        if (!passwordEncoder.matches(
                password,
                user.getPasswordHash())) {

            throw new InvalidPasswordException(
                    "Password verification failed. Cannot delete account."
            );
        }

        refreshTokenRepository.revokeAllByUser(user);

        userRepository.delete(user);

        log.info(
                "Account deleted for userId={}",
                userId
        );
    }
}