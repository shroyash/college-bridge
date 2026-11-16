package com.college.bridge.notification.service;

import com.college.bridge.notification.fcm.DesiredTopicResolver;
import com.college.bridge.notification.fcm.DeviceSubscriptionStore;
import com.college.bridge.notification.fcm.FcmNotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationTopicSyncService {

    private final DesiredTopicResolver topicResolver;
    private final DeviceSubscriptionStore subscriptionStore;
    private final FcmNotificationService fcmService;

    public void syncDeviceTopics(Long deviceId, String token, Long userId) {
        Optional<Set<String>> desiredOpt = topicResolver.resolve(userId);
        if (desiredOpt.isEmpty()) return;

        Set<String> desired = desiredOpt.get();
        Set<String> current = subscriptionStore.currentTopics(deviceId);

        Set<String> toAdd = new HashSet<>(desired);
        toAdd.removeAll(current);
        Set<String> toRemove = new HashSet<>(current);
        toRemove.removeAll(desired);

        // Firebase first, then DB only after Firebase confirms.
        // Each DB write commits on its own, so progress survives a later failure.
        for (String topic : toRemove) {
            fcmService.unsubscribeTokensFromTopic(List.of(token), topic);
        }
        if (!toRemove.isEmpty()) {
            subscriptionStore.remove(deviceId, toRemove);
        }

        for (String topic : toAdd) {
            fcmService.subscribeTokensToTopic(List.of(token), topic);
            try {
                subscriptionStore.add(deviceId, topic);
            } catch (DataIntegrityViolationException e) {
                log.debug("Subscription row for device {} / topic {} already exists", deviceId, topic);
            }
        }
    }

    public void unsubscribeTokenFromTopics(String token, List<String> topics) {
        for (String topic : topics) {
            fcmService.unsubscribeTokensFromTopic(List.of(token), topic);
        }
    }
}