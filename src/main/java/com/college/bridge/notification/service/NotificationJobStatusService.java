package com.college.bridge.notification.service;

import com.college.bridge.notification.entity.JobStatus;
import com.college.bridge.notification.entity.RecipientDeliveryStatus;
import com.college.bridge.notification.repository.FcmDeviceRepository;
import com.college.bridge.notification.repository.NotificationRecipientRepository;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationJobStatusService {

    private final EntityManager entityManager;
    private final NotificationRecipientRepository recipientRepository;
    private final FcmDeviceRepository fcmDeviceRepository;

    @Transactional
    public void markJobSent(Long jobId, int expectedAttempt) {
        int updated = entityManager.createQuery("""
            UPDATE NotificationJob j
            SET j.status = :status, j.lastError = null, j.updatedAt = :now
            WHERE j.jobId = :jobId AND j.status = :procStatus AND j.attemptCount = :attempt
        """)
        .setParameter("status", JobStatus.SENT)
        .setParameter("procStatus", JobStatus.PROCESSING)
        .setParameter("attempt", expectedAttempt)
        .setParameter("jobId", jobId)
        .setParameter("now", Instant.now())
        .executeUpdate();

        if (updated == 0) {
            log.warn("Fencing check failed for job {}. Lease was reclaimed by another worker.", jobId);
        }
    }

    @Transactional
    public void handleJobFailure(Long jobId, int expectedAttempt, int maxAttempts, String error, boolean isTransient) {
        JobStatus nextStatus = (!isTransient || expectedAttempt >= maxAttempts) ? JobStatus.DEAD : JobStatus.RETRYING;
        Instant nextAttemptAt = Instant.now();

        if (nextStatus == JobStatus.RETRYING) {
            long backoffSeconds = 30L * (1L << Math.min(expectedAttempt - 1, 6));
            nextAttemptAt = nextAttemptAt.plus(backoffSeconds, ChronoUnit.SECONDS);
        }

        int updated = entityManager.createQuery("""
            UPDATE NotificationJob j
            SET j.status = :status, j.lastError = :error, j.nextAttemptAt = :nextAttempt, j.updatedAt = :now
            WHERE j.jobId = :jobId AND j.status = :procStatus AND j.attemptCount = :attempt
        """)
        .setParameter("status", nextStatus)
        .setParameter("error", error)
        .setParameter("nextAttempt", nextAttemptAt)
        .setParameter("procStatus", JobStatus.PROCESSING)
        .setParameter("attempt", expectedAttempt)
        .setParameter("jobId", jobId)
        .setParameter("now", Instant.now())
        .executeUpdate();

        if (updated == 0) {
            log.warn("Fencing check failed on failure update for job {}.", jobId);
        }
    }

    @Transactional
    public void updateRecipientBatch(List<Long> deliveredRecipientIds, List<Long> failedRecipientIds, List<String> unregisteredTokens) {
        Instant now = Instant.now();
        if (deliveredRecipientIds != null && !deliveredRecipientIds.isEmpty()) {
            recipientRepository.updateStatusForIds(deliveredRecipientIds, RecipientDeliveryStatus.SENT, now);
        }
        if (failedRecipientIds != null && !failedRecipientIds.isEmpty()) {
            recipientRepository.updateStatusForIds(failedRecipientIds, RecipientDeliveryStatus.FAILED, now);
        }
        if (unregisteredTokens != null && !unregisteredTokens.isEmpty()) {
            fcmDeviceRepository.deactivateTokens(unregisteredTokens, now);
        }
    }
}
