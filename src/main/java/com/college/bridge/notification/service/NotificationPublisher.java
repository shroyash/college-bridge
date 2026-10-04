package com.college.bridge.notification.service;

import com.college.bridge.notification.dto.NotificationPublishRequest;
import com.college.bridge.notification.entity.Notification;
import com.college.bridge.notification.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationPublisher {

    private final NotificationInternalTxWriter txWriter;
    private final NotificationRepository notificationRepository;

    public Notification publish(NotificationPublishRequest request) {
        String key = request.getIdempotencyKey();
        try {
            return txWriter.createNotificationTransactional(request);
        } catch (DataIntegrityViolationException e) {
            log.info("Idempotency key collision for key: '{}'. Fetching existing notification.", key);
            if (key != null && !key.isBlank()) {
                Optional<Notification> existing = notificationRepository.findByIdempotencyKey(key.trim());
                if (existing.isPresent()) {
                    return existing.get();
                }
            }
            throw e;
        }
    }
}
