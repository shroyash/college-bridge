package com.college.bridge.notification.service;

import com.college.bridge.notification.dto.NotificationJobExecutionDto;
import com.college.bridge.notification.entity.FcmDevice;
import com.college.bridge.notification.entity.NotificationRecipient;
import com.college.bridge.notification.entity.RecipientDeliveryStatus;
import com.college.bridge.notification.fcm.FcmErrorClassifier;
import com.college.bridge.notification.fcm.FcmNotificationService;
import com.college.bridge.notification.repository.FcmDeviceRepository;
import com.college.bridge.notification.repository.NotificationRecipientRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationJobProcessor {

    private final NotificationRecipientRepository recipientRepository;
    private final FcmDeviceRepository fcmDeviceRepository;
    private final FcmNotificationService fcmService;
    private final NotificationJobStatusService statusService;

    // NO @Transactional: Firebase Admin SDK calls execute over the network without holding DB locks
    public void processJob(NotificationJobExecutionDto jobDto) {
        Long jobId = jobDto.getJobId();
        Long institutionId = jobDto.getInstitutionId();
        int attemptCount = jobDto.getAttemptCount();
        int maxAttempts = jobDto.getMaxAttempts();

        try {
            Map<String, String> dataPayload = new HashMap<>();
            dataPayload.put("notificationId", String.valueOf(jobDto.getNotificationId()));
            dataPayload.put("targetType", jobDto.getTargetType().name());
            dataPayload.put("institutionId", String.valueOf(institutionId));
            if (jobDto.getTargetId() != null) {
                dataPayload.put("targetId", String.valueOf(jobDto.getTargetId()));
            }

            switch (jobDto.getTargetType()) {
                case INSTITUTION -> {
                    String topic = "tenant_" + institutionId + "_all";
                    fcmService.sendToTopic(topic, jobDto.getTitle(), jobDto.getBody(), dataPayload);
                    statusService.markJobSent(jobId, attemptCount);
                }
                case CLASS -> {
                    String topic = "tenant_" + institutionId + "_class_" + jobDto.getTargetId();
                    fcmService.sendToTopic(topic, jobDto.getTitle(), jobDto.getBody(), dataPayload);
                    statusService.markJobSent(jobId, attemptCount);
                }
                case SUBJECT -> {
                    String topic = "tenant_" + institutionId + "_subject_" + jobDto.getTargetId();
                    fcmService.sendToTopic(topic, jobDto.getTitle(), jobDto.getBody(), dataPayload);
                    statusService.markJobSent(jobId, attemptCount);
                }
                case USERS -> processDirectUsersMulticast(jobDto, dataPayload);
            }
        } catch (Exception e) {
            boolean isTransient = FcmErrorClassifier.isTransient(e);
            log.warn("FCM error on job {}: [transient={}] {}", jobId, isTransient, e.getMessage());
            statusService.handleJobFailure(jobId, attemptCount, maxAttempts, e.getMessage(), isTransient);
        }
    }

    private void processDirectUsersMulticast(
            NotificationJobExecutionDto jobDto,
            Map<String, String> dataPayload) throws Exception {

        Long notificationId = jobDto.getNotificationId();
        Long jobId = jobDto.getJobId();
        int attemptCount = jobDto.getAttemptCount();
        int maxAttempts = jobDto.getMaxAttempts();

        List<NotificationRecipient> pendingRecipients = recipientRepository
                .findByNotificationIdAndDeliveryStatus(notificationId, RecipientDeliveryStatus.PENDING);

        if (pendingRecipients.isEmpty()) {
            statusService.markJobSent(jobId, attemptCount);
            return;
        }

        Map<Long, Long> userIdToRecipientId = new HashMap<>();
        List<Long> pendingUserIds = new ArrayList<>();
        for (NotificationRecipient nr : pendingRecipients) {
            Long uId = nr.getUser().getUserId();
            userIdToRecipientId.put(uId, nr.getRecipientId());
            pendingUserIds.add(uId);
        }

        List<FcmDevice> activeDevices = fcmDeviceRepository
                .findActiveDevicesByUserIds(pendingUserIds, jobDto.getInstitutionId());

        if (activeDevices.isEmpty()) {
            // No active registered devices for these users
            List<Long> failedRecipientIds = pendingRecipients.stream()
                    .map(NotificationRecipient::getRecipientId)
                    .toList();
            statusService.updateRecipientBatch(List.of(), failedRecipientIds, List.of());
            statusService.markJobSent(jobId, attemptCount);
            return;
        }

        // Map token to recipientId
        List<String> tokens = new ArrayList<>();
        Map<String, Long> tokenToRecipientId = new HashMap<>();
        Set<Long> usersWithDevices = new HashSet<>();

        for (FcmDevice device : activeDevices) {
            String token = device.getFcmToken();
            Long uId = device.getUser().getUserId();
            Long recipientId = userIdToRecipientId.get(uId);
            if (recipientId != null) {
                tokens.add(token);
                tokenToRecipientId.put(token, recipientId);
                usersWithDevices.add(uId);
            }
        }

        // Recipients with no devices at all can be marked FAILED immediately
        List<Long> usersWithoutDeviceRecipientIds = new ArrayList<>();
        for (NotificationRecipient nr : pendingRecipients) {
            if (!usersWithDevices.contains(nr.getUser().getUserId())) {
                usersWithoutDeviceRecipientIds.add(nr.getRecipientId());
            }
        }
        if (!usersWithoutDeviceRecipientIds.isEmpty()) {
            statusService.updateRecipientBatch(List.of(), usersWithoutDeviceRecipientIds, List.of());
        }

        // Send tokens in batches of up to 500
        int batchSize = 500;
        boolean hasTransientFailure = false;

        for (int i = 0; i < tokens.size(); i += batchSize) {
            List<String> batchTokens = tokens.subList(i, Math.min(i + batchSize, tokens.size()));
            var batchResult = fcmService.sendToTokens(batchTokens, jobDto.getTitle(), jobDto.getBody(), dataPayload);

            List<Long> deliveredIds = new ArrayList<>();
            List<Long> failedIds = new ArrayList<>();

            for (Integer idx : batchResult.successfulIndices()) {
                String token = batchTokens.get(idx);
                Long rId = tokenToRecipientId.get(token);
                if (rId != null) {
                    deliveredIds.add(rId);
                }
            }

            for (Integer idx : batchResult.permanentFailureIndices()) {
                String token = batchTokens.get(idx);
                Long rId = tokenToRecipientId.get(token);
                if (rId != null) {
                    failedIds.add(rId);
                }
            }

            // A user may have multiple devices. If at least one device delivered successfully,
            // remove that recipientId from failedIds — the recipient is considered SENT.
            failedIds.removeAll(deliveredIds);

            statusService.updateRecipientBatch(deliveredIds, failedIds, batchResult.unregisteredTokens());

            if (!batchResult.transientFailureIndices().isEmpty()) {
                hasTransientFailure = true;
            }
        }

        if (hasTransientFailure) {
            statusService.handleJobFailure(jobId, attemptCount, maxAttempts, "Transient multicast failure", true);
        } else {
            statusService.markJobSent(jobId, attemptCount);
        }
    }
}
