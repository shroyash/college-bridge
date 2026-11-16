package com.college.bridge.notification.fcm;

import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.notification.dto.DeviceDeactivationResult;
import com.college.bridge.notification.dto.DeviceRegistrationResult;
import com.college.bridge.notification.entity.FcmDevice;
import com.college.bridge.notification.repository.DeviceTopicSubscriptionRepository;
import com.college.bridge.notification.repository.FcmDeviceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class FcmDeviceWriter {

    private final FcmDeviceRepository deviceRepository;
    private final DeviceTopicSubscriptionRepository subscriptionRepository;
    private final UserRepository userRepository;

    @Transactional
    public DeviceRegistrationResult saveOrUpdateDevice(String token, String platform, Long userId) {
        User user = userRepository.findById(userId).orElseThrow();
        Optional<FcmDevice> existing = deviceRepository.findByFcmToken(token);

        if (existing.isEmpty()) {
            FcmDevice created = deviceRepository.save(FcmDevice.builder()
                    .user(user).institution(user.getInstitution())
                    .fcmToken(token).platform(platform)
                    .active(true).lastSeenAt(Instant.now()).build());
            return new DeviceRegistrationResult(created.getDeviceId(), token, false, List.of());
        }

        FcmDevice device = existing.get();
        boolean reassigned = !device.getUser().getUserId().equals(userId);
        List<String> oldTopics = List.of();

        if (reassigned) {
            oldTopics = subscriptionRepository.findTopicsByDeviceId(device.getDeviceId());
            device.setUser(user);
            device.setInstitution(user.getInstitution());
        }
        device.setPlatform(platform);
        device.setActive(true);
        device.setLastSeenAt(Instant.now());
        deviceRepository.saveAndFlush(device);                               // device changes first

        if (reassigned) {
            subscriptionRepository.deleteByDeviceId(device.getDeviceId());   // bulk delete last
        }
        return new DeviceRegistrationResult(device.getDeviceId(), token, reassigned, oldTopics);
    }

    @Transactional
    public Optional<DeviceDeactivationResult> deactivateDevice(String token, Long userId) {
        return deviceRepository.findByFcmToken(token)
                .filter(d -> d.getUser().getUserId().equals(userId))         // only the owner
                .map(device -> {
                    List<String> topics = subscriptionRepository.findTopicsByDeviceId(device.getDeviceId());
                    device.setActive(false);
                    deviceRepository.saveAndFlush(device);
                    subscriptionRepository.deleteByDeviceId(device.getDeviceId());
                    return new DeviceDeactivationResult(token, topics);
                });
    }
}
