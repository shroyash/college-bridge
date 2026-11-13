package com.college.bridge.holiday.application.notice;

import com.college.bridge.holiday.config.NepalClock;
import com.college.bridge.holiday.domain.InstitutionNoticeRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * Policy: institutional sovereignty includes "no action". If a college never decided, nothing is announced
 * for it; once the holiday has passed the notice is marked EXPIRED. The AI never declares a closure.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class NoticeExpiryService {

    private final InstitutionNoticeRepository notices;
    private final NepalClock clock;

    public void expireOverdueNotices() {
        int expired = notices.expireOverdue(clock.today(), clock.instantNow());
        if (expired > 0) {
            log.info("Expired {} undecided holiday notices", expired);
        }
    }
}
