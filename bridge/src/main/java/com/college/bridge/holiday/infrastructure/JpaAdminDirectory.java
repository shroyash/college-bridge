package com.college.bridge.holiday.infrastructure;

import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.holiday.application.port.AdminDirectory;
import com.college.bridge.notification.entity.FcmDevice;
import com.college.bridge.notification.repository.FcmDeviceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;

@Component
@Slf4j
@RequiredArgsConstructor
public class JpaAdminDirectory implements AdminDirectory {

    private final UserRepository userRepository;
    private final FcmDeviceRepository fcmDeviceRepository;

    @Override
    public List<AdminDevice> activeDevices(Long institutionId) {
        if (institutionId == null) {
            return List.of();
        }

        List<User> admins = userRepository.findByInstitution_InstitutionIdAndRole(institutionId, UserRole.ADMIN);
        if (admins.isEmpty()) {
            return List.of();
        }

        List<Long> adminUserIds = admins.stream()
                .map(User::getUserId)
                .toList();

        List<AdminDevice> devices = new ArrayList<>();
        Set<String> seenTokens = new HashSet<>();

        // Check active FCM devices registered in FcmDevice table
        List<FcmDevice> activeFcmDevices = fcmDeviceRepository.findActiveDevicesByUserIds(adminUserIds, institutionId);
        for (FcmDevice device : activeFcmDevices) {
            String token = device.getFcmToken();
            if (token != null && !token.isBlank() && seenTokens.add(token)) {
                devices.add(new AdminDevice(device.getUser().getUserId(), token));
            }
        }

        // Also check User.fcmToken if present as fallback
        for (User admin : admins) {
            String token = admin.getFcmToken();
            if (token != null && !token.isBlank() && seenTokens.add(token)) {
                devices.add(new AdminDevice(admin.getUserId(), token));
            }
        }

        return devices;
    }

    @Override
    public Optional<Long> findAnyAdminId(Long institutionId) {
        if (institutionId == null) {
            return Optional.empty();
        }
        return userRepository.findByInstitution_InstitutionIdAndRole(institutionId, UserRole.ADMIN)
                .stream()
                .map(User::getUserId)
                .findFirst();
    }

    @Override
    @Transactional
    public void forget(Collection<String> deviceTokens) {
        if (deviceTokens == null || deviceTokens.isEmpty()) {
            return;
        }
        try {
            fcmDeviceRepository.deactivateTokens(new ArrayList<>(deviceTokens), Instant.now());
        } catch (Exception e) {
            log.warn("Failed to deactivate dead device tokens: {}", e.getMessage());
        }
    }
}
