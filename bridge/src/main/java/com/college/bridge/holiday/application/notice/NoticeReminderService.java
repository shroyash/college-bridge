package com.college.bridge.holiday.application.notice;

import com.college.bridge.holiday.application.port.AdminAlerts;
import com.college.bridge.holiday.domain.InstitutionNoticeRepository;
import com.college.bridge.holiday.domain.NoticeStatus;
import com.college.bridge.holiday.domain.PublicHolidayRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDate;

/** Use case: nudge each institution's admins about notices that still need their decision. */
@Service
@Slf4j
@RequiredArgsConstructor
public class NoticeReminderService {

    private final InstitutionNoticeRepository notices;
    private final PublicHolidayRepository holidays;
    private final AdminAlerts adminAlerts;

    public void remindUndecided(LocalDate holidayDate) {
        notices.findByHolidayDateAndStatus(holidayDate, NoticeStatus.AWAITING_DECISION).forEach(notice ->
                holidays.findById(notice.getHolidayId()).ifPresent(holiday -> {
                    try {
                        adminAlerts.approvalRequested(notice.getInstitutionId(), holiday, true);
                    } catch (RuntimeException e) {
                        log.warn("Reminder failed for institution {} / holiday {}",
                                notice.getInstitutionId(), holiday.getId(), e);
                    }
                }));
    }
}
