package com.college.bridge.holiday.application.notice;

import com.college.bridge.holiday.application.port.AdminAlerts;
import com.college.bridge.holiday.application.port.AudienceBroadcaster;
import com.college.bridge.holiday.application.port.AudienceBroadcaster.Broadcast;
import com.college.bridge.holiday.application.port.InstitutionDirectory;
import com.college.bridge.holiday.config.HolidayProperties;
import com.college.bridge.holiday.config.NepalClock;
import com.college.bridge.holiday.domain.InstitutionNotice;
import com.college.bridge.holiday.domain.InstitutionNoticeRepository;
import com.college.bridge.holiday.domain.PublicHolidayRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;

/**
 * Outbox worker: delivers each approved institution notice by push, exactly once in the normal case.
 * Approval is already committed and visible in the app; a push failure never undoes it.
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
    private final AudienceBroadcaster broadcaster;
    private final AdminAlerts adminAlerts;
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
