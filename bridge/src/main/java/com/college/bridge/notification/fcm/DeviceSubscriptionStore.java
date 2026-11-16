package com.college.bridge.notification.fcm;

import com.college.bridge.notification.entity.DeviceTopicSubscription;
import com.college.bridge.notification.repository.DeviceTopicSubscriptionRepository;
import com.college.bridge.notification.repository.FcmDeviceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collection;
import java.util.HashSet;
import java.util.Set;

@Component
@RequiredArgsConstructor
public class DeviceSubscriptionStore {

    private final DeviceTopicSubscriptionRepository subscriptionRepository;
    private final FcmDeviceRepository deviceRepository;

    @Transactional(readOnly = true)
    public Set<String> currentTopics(Long deviceId) {
        return new HashSet<>(subscriptionRepository.findTopicsByDeviceId(deviceId));
    }

    @Transactional
    public void add(Long deviceId, String topic) {
        subscriptionRepository.save(DeviceTopicSubscription.builder()
                .device(deviceRepository.getReferenceById(deviceId))
                .topic(topic)
                .build());                       // @CreationTimestamp sets createdAt
    }

    @Transactional
    public void remove(Long deviceId, Collection<String> topics) {
        subscriptionRepository.deleteByDevice_DeviceIdAndTopicIn(deviceId, topics);
    }
}