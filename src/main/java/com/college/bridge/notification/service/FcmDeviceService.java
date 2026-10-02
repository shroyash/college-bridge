package com.college.bridge.notification.service;

import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.institution.entity.Institution;
import com.college.bridge.notification.dto.RegisterDeviceRequest;
import com.college.bridge.notification.entity.FcmDevice;
import com.college.bridge.notification.repository.FcmDeviceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class FcmDeviceService {

    private final FcmDeviceRepository fcmDeviceRepository;
    private final NotificationTopicSyncService topicSyncService;

    public void registerDevice(RegisterDeviceRequest request, UserPrincipal principal) {
        User user = principal.getUser();
        String token = request.getToken().trim();
        String platform = request.getPlatform().trim().toUpperCase();

        // Step 1: Save/update device in short database transaction
        FcmDevice savedDevice = saveOrUpdateDevice(token, platform, user);

        // Step 2: Synchronize topic subscriptions with FCM outside transaction
        try {
            topicSyncService.syncDeviceTopics(savedDevice, user);
        } catch (Exception e) {
            log.warn("Failed to synchronize FCM topics for device {}: {}", savedDevice.getDeviceId(), e.getMessage());
        }
    }

    @Transactional
    public FcmDevice saveOrUpdateDevice(String token, String platform, User user) {
        Institution institution = user.getInstitution();
        Optional<FcmDevice> existingDeviceOpt = fcmDeviceRepository.findByFcmToken(token);

        if (existingDeviceOpt.isPresent()) {
            FcmDevice device = existingDeviceOpt.get();
            // Check if device is reassigned to another user
            if (!device.getUser().getUserId().equals(user.getUserId())) {
                topicSyncService.unsubscribeAllFromDevice(device);
                device.setUser(user);
                device.setInstitution(institution);
            }
            device.setPlatform(platform);
            device.setActive(true);
            device.setLastSeenAt(Instant.now());
            device.setUpdatedAt(Instant.now());
            return fcmDeviceRepository.save(device);
        } else {
            FcmDevice newDevice = FcmDevice.builder()
                    .user(user)
                    .institution(institution)
                    .fcmToken(token)
                    .platform(platform)
                    .active(true)
                    .lastSeenAt(Instant.now())
                    .build();
            return fcmDeviceRepository.save(newDevice);
        }
    }

    @Transactional
    public void deactivateDevice(String token, UserPrincipal principal) {
        String cleanToken = token.trim();
        fcmDeviceRepository.findByFcmToken(cleanToken).ifPresent(device -> {
            if (device.getUser().getUserId().equals(principal.getUserId())) {
                device.setActive(false);
                device.setUpdatedAt(Instant.now());
                fcmDeviceRepository.save(device);
                topicSyncService.unsubscribeAllFromDevice(device);
            }
        });
    }
}
