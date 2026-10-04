package com.college.bridge.notification.service;

import com.college.bridge.notification.entity.FcmDevice;
import com.college.bridge.notification.repository.FcmDeviceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.util.Collection;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class UserTopicRefreshService {

    private final FcmDeviceRepository fcmDeviceRepository;
    private final NotificationTopicSyncService topicSyncService;

    @Async("topicRefreshTaskExecutor")
    public void refreshTopicsForUser(Long userId) {
        if (userId == null) return;
        try {
            List<FcmDevice> devices = fcmDeviceRepository.findByUser_UserIdAndActiveTrue(userId);
            for (FcmDevice device : devices) {
                try {
                    topicSyncService.syncDeviceTopics(device.getDeviceId(), device.getFcmToken(), userId);
                } catch (Exception e) {
                    log.warn("Failed to sync FCM topics for device {} of user {}: {}",
                            device.getDeviceId(), userId, e.getMessage());
                }
            }
        } catch (Exception e) {
            log.error("Error refreshing topics for user {}: {}", userId, e.getMessage(), e);
        }
    }

    @Async("topicRefreshTaskExecutor")
    public void refreshTopicsForUsers(Collection<Long> userIds) {
        if (userIds == null || userIds.isEmpty()) return;
        List<Long> distinctIds = userIds.stream().filter(id -> id != null).distinct().toList();
        int batchSize = 50;
        for (int i = 0; i < distinctIds.size(); i += batchSize) {
            List<Long> batch = distinctIds.subList(i, Math.min(i + batchSize, distinctIds.size()));
            for (Long userId : batch) {
                refreshTopicsForUser(userId);
            }
        }
    }
}
