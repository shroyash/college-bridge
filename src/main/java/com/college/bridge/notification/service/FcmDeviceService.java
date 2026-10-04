package com.college.bridge.notification.service;

import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.institution.entity.Institution;
import com.college.bridge.notification.dto.DeviceRegistrationResult;
import com.college.bridge.notification.dto.RegisterDeviceRequest;
import com.college.bridge.notification.entity.FcmDevice;
import com.college.bridge.notification.exception.FcmException;
import com.college.bridge.notification.fcm.FcmDeviceWriter;
import com.college.bridge.notification.repository.FcmDeviceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class FcmDeviceService {

    private final FcmDeviceWriter deviceWriter;
    private final NotificationTopicSyncService topicSyncService;

    public void registerDevice(RegisterDeviceRequest request, UserPrincipal principal) {
        Long userId = principal.getUserId();
        String token = request.getToken().trim();
        String platform = request.getPlatform().trim().toUpperCase();

        DeviceRegistrationResult result = saveWithRetry(token, platform, userId);

        try {
            if (result.reassigned() && !result.oldTopics().isEmpty()) {
                topicSyncService.unsubscribeTokenFromTopics(token, result.oldTopics());
            }
            topicSyncService.syncDeviceTopics(result.deviceId(), result.token(), userId);
        } catch (FcmException e) {
            // Not fatal: the app calls register on every start, so the sync is retried then
            log.warn("Topic sync failed for device {} (retryable={})",
                    result.deviceId(), e.isRetryable(), e);
        }
    }

    public void deactivateDevice(String token, UserPrincipal principal) {
        String cleanToken = token.trim();

        deviceWriter.deactivateDevice(cleanToken, principal.getUserId())
                .ifPresent(result -> {
                    if (result.topics().isEmpty()) return;
                    try {
                        topicSyncService.unsubscribeTokenFromTopics(result.token(), result.topics());
                    } catch (FcmException e) {
                        log.error("Failed to unsubscribe deactivated device from {} topics",
                                result.topics().size(), e);
                    }
                });
    }


    private DeviceRegistrationResult saveWithRetry(String token, String platform, Long userId) {
        try {
            return deviceWriter.saveOrUpdateDevice(token, platform, userId);
        } catch (DataIntegrityViolationException e) {
            log.debug("Concurrent registration for the same token, retrying once");
            return deviceWriter.saveOrUpdateDevice(token, platform, userId);
        }
    }
}