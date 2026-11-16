package com.college.bridge.notification.service;

import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.institution.entity.Institution;
import com.college.bridge.institution.repository.InstitutionRepository;
import com.college.bridge.notification.dto.NotificationPublishRequest;
import com.college.bridge.notification.entity.*;
import com.college.bridge.notification.repository.NotificationJobRepository;
import com.college.bridge.notification.repository.NotificationRecipientRepository;
import com.college.bridge.notification.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationInternalTxWriter {

    private final NotificationRepository notificationRepository;
    private final NotificationJobRepository jobRepository;
    private final NotificationRecipientRepository recipientRepository;
    private final UserRepository userRepository;
    private final InstitutionRepository institutionRepository;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public Notification createNotificationTransactional(NotificationPublishRequest request) {
        String key = request.getIdempotencyKey();
        if (key != null && !key.isBlank()) {
            Optional<Notification> existing = notificationRepository.findByIdempotencyKey(key.trim());
            if (existing.isPresent()) {
                return existing.get();
            }
        }

        Long institutionId = request.getInstitutionId();
        Institution institution = (institutionId != null)
                ? institutionRepository.findById(institutionId).orElse(null)
                : null;

        User sender = null;
        if (request.getSenderUserId() != null) {
            sender = userRepository.findById(request.getSenderUserId()).orElse(null);
        }

        String title = request.getTitle() != null ? request.getTitle().trim() : "Notification";
        if (title.length() > 200) {
            title = title.substring(0, 197) + "...";
        }

        String body = request.getBody() != null ? request.getBody().trim() : "";
        if (body.length() > 4000) {
            body = body.substring(0, 3997) + "...";
        }

        Notification notification = Notification.builder()
                .institution(institution)
                .title(title)
                .message(body)
                .sender(sender)
                .targetType(request.getTargetType())
                .targetId(request.getTargetId())
                .type(request.getType())
                .status(NotificationStatus.PENDING)
                .priority(NotificationPriority.MEDIUM)
                .idempotencyKey(key != null && !key.isBlank() ? key.trim() : null)
                .createdAt(Instant.now())
                .build();

        Notification saved = notificationRepository.saveAndFlush(notification);

        if (request.getTargetType() == NotificationTargetType.USERS && request.getUserIds() != null && !request.getUserIds().isEmpty()) {
            List<Long> targetUserIds = request.getUserIds().stream().distinct().toList();
            List<User> validUsers = userRepository.findByUserIdInAndInstitutionId(targetUserIds, institutionId);

            List<NotificationRecipient> batch = new ArrayList<>();
            for (User u : validUsers) {
                if (u.isDeleted() || u.getStatus() != com.college.bridge.auth.entity.UserStatus.ACTIVE) {
                    continue;
                }
                batch.add(NotificationRecipient.builder()
                        .notification(saved)
                        .user(u)
                        .deliveryStatus(RecipientDeliveryStatus.PENDING)
                        .build());

                if (batch.size() >= 500) {
                    recipientRepository.saveAll(batch);
                    recipientRepository.flush();
                    batch.clear();
                }
            }
            if (!batch.isEmpty()) {
                recipientRepository.saveAll(batch);
                recipientRepository.flush();
            }
        }

        NotificationJob job = NotificationJob.builder()
                .notification(saved)
                .institutionId(institutionId != null ? institutionId : 0L)
                .status(JobStatus.PENDING)
                .attemptCount(0)
                .maxAttempts(5)
                .nextAttemptAt(Instant.now())
                .createdAt(Instant.now())
                .build();

        jobRepository.save(job);

        return saved;
    }
}
