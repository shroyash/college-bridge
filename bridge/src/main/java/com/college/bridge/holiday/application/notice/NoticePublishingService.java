package com.college.bridge.holiday.application.notice;

import com.college.bridge.holiday.application.port.AdminAlerts;
import com.college.bridge.holiday.application.port.AdminDirectory;
import com.college.bridge.holiday.application.port.AudienceBroadcaster;
import com.college.bridge.holiday.application.port.AudienceBroadcaster.Broadcast;
import com.college.bridge.holiday.application.port.InstitutionDirectory;
import com.college.bridge.holiday.config.HolidayProperties;
import com.college.bridge.holiday.config.NepalClock;
import com.college.bridge.holiday.domain.InstitutionNotice;
import com.college.bridge.holiday.domain.InstitutionNoticeRepository;
import com.college.bridge.holiday.domain.PublicHolidayRepository;
import com.college.bridge.notification.dto.NotificationPublishRequest;
import com.college.bridge.notification.entity.NotificationTargetType;
import com.college.bridge.notification.entity.NotificationType;
import com.college.bridge.notification.service.NotificationPublisher;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;

/**
 * Outbox worker: delivers each approved institution notice by push, exactly once in the normal case.
 * Approval is already committed and visible in the app; a push failure never undoes it.
 *
 * <p>After a successful FCM broadcast, it also writes the notice into the unified notification
 * inbox (via {@link NotificationPublisher}) so students and teachers see it in their notification
 * bell even if their device was not subscribed to the audience topics at broadcast time.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class NoticePublishingService {

    private static final int MAX_ERROR_LENGTH = 500;
    private static final long MAX_BACKOFF_MINUTES = 30;

    private final InstitutionNoticeRepository notices;
    private final PublicHolidayRepository holidays;
    private final InstitutionDirectory institutions;
    private final AdminDirectory adminDirectory;
    private final AudienceBroadcaster broadcaster;
    private final AdminAlerts adminAlerts;
    private final NotificationPublisher notificationPublisher;
    private final HolidayProperties props;
    private final NepalClock clock;

    public void publishDueNotices() {
        reclaimStuckNotices();
        Instant now = clock.instantNow();
        for (InstitutionNotice notice : notices.findDueForPublishing(now, PageRequest.of(0, props.publishing().batchSize()))) {
            publish(notice);
        }
    }

    /** Stale lease recovery: a crashed server leaves rows in PUBLISHING; they go back to the queue. */
    private void reclaimStuckNotices() {
        Instant now = clock.instantNow();
        Instant cutoff = now.minus(Duration.ofMinutes(props.publishing().staleAfterMinutes()));
        int reclaimed = notices.reclaimStalePublishing(cutoff, now);
        if (reclaimed > 0) {
            log.warn("Reclaimed {} notices stuck in PUBLISHING", reclaimed);
        }
    }

    private void publish(InstitutionNotice notice) {
        // Atomic claim: if another server already took it, we simply skip.
        if (notices.claimForPublishing(notice.getId(), clock.instantNow()) == 0) {
            return;
        }

        // 1. Always record in the unified in-app notification inbox first so users
        // see the announcement in their bell icon, even if FCM topic push fails or is blocked.
        publishToInbox(notice);

        // 2. Broadcast via FCM topic push to role-specific audience (students/teachers)
        int attempt = notice.getPublishAttempts() + 1;
        try {
            broadcaster.broadcast(new Broadcast(
                    notice.getInstitutionId(), notice.getHolidayId(), institutions.nameOf(notice.getInstitutionId()),
                    notice.getFinalTitle(), notice.getFinalBody(),
                    notice.isNotifyStudents(), notice.isNotifyTeachers()));
            notices.markPublished(notice.getId(), clock.instantNow());
            log.info("Holiday notice {} published for institution {}", notice.getHolidayId(), notice.getInstitutionId());
        } catch (RuntimeException e) {
            recordFailure(notice, attempt, e);
        }
    }

    /**
     * Writes the holiday notice into the shared notification system (notifications table +
     * notification_jobs). The job processor will push it via the tenant_X_all topic and store it
     * in the per-user read-state so users see it in their inbox.
     * Uses an idempotency key so re-runs (after a crash/retry) never create duplicates.
     */
    private void publishToInbox(InstitutionNotice notice) {
        try {
            Long senderId = notice.getDecidedBy();
            if (senderId == null) {
                senderId = adminDirectory.findAnyAdminId(notice.getInstitutionId()).orElse(null);
            }

            String idempotencyKey = "holiday-notice-" + notice.getHolidayId() + "-" + notice.getInstitutionId();
            notificationPublisher.publish(NotificationPublishRequest.builder()
                    .institutionId(notice.getInstitutionId())
                    .senderUserId(senderId)
                    .title(notice.getFinalTitle())
                    .body(notice.getFinalBody())
                    .targetType(NotificationTargetType.INSTITUTION)
                    .type(NotificationType.HOLIDAY)
                    .idempotencyKey(idempotencyKey)
                    .build());
        } catch (RuntimeException e) {
            // Inbox write failure must NOT roll back the FCM publish — the notice is already delivered.
            log.warn("Could not write holiday notice {} / institution {} to notification inbox: {}",
                    notice.getHolidayId(), notice.getInstitutionId(), e.getMessage());
        }
    }

    private void recordFailure(InstitutionNotice notice, int attempt, RuntimeException failure) {
        int maxAttempts = props.publishing().maxAttempts();
        String error = truncate(failure.getMessage());
        Instant now = clock.instantNow();
        log.error("Publishing holiday notice {} for institution {} failed (attempt {}/{})",
                notice.getHolidayId(), notice.getInstitutionId(), attempt, maxAttempts, failure);

        if (attempt >= maxAttempts) {
            notices.markFailed(notice.getId(), error, now);
            holidays.findById(notice.getHolidayId()).ifPresent(holiday -> {
                try {
                    adminAlerts.publishingFailed(notice.getInstitutionId(), holiday);
                } catch (RuntimeException alertFailure) {
                    log.warn("Could not alert admins about the failed publish", alertFailure);
                }
            });
        } else {
            // Exponential backoff: 2, 4, 8, 16 ... minutes (capped).
            long minutes = Math.min(MAX_BACKOFF_MINUTES, 1L << attempt);
            notices.returnToApproved(notice.getId(), error, now.plus(Duration.ofMinutes(minutes)), now);
        }
    }

    private static String truncate(String message) {
        if (message == null) return null;
        return message.length() <= MAX_ERROR_LENGTH ? message : message.substring(0, MAX_ERROR_LENGTH);
    }
}
