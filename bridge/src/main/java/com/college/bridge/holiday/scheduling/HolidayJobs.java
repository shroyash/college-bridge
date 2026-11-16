package com.college.bridge.holiday.scheduling;

import com.college.bridge.holiday.application.calendar.HolidayCalendarSyncService;
import com.college.bridge.holiday.application.notice.NoticeDraftingService;
import com.college.bridge.holiday.application.notice.NoticeExpiryService;
import com.college.bridge.holiday.application.notice.NoticePublishingService;
import com.college.bridge.holiday.application.notice.NoticeReminderService;
import com.college.bridge.holiday.config.HolidayProperties;
import com.college.bridge.holiday.config.NepalClock;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.List;

/**
 * Cron triggers only: each method says WHEN and delegates the WHAT to a use-case service.
 * Every job is idempotent and every state change is an atomic conditional update,
 * so restarts and multiple servers are safe.
 */
@Component
@Slf4j
@RequiredArgsConstructor
public class HolidayJobs {

    private final HolidayCalendarSyncService calendarSync;
    private final NoticeDraftingService drafting;
    private final NoticeReminderService reminders;
    private final NoticeExpiryService expiry;
    private final NoticePublishingService publishing;
    private final HolidayProperties props;
    private final NepalClock clock;


    @Scheduled(cron = "${holiday.schedule.sync:0 0 2 1 * *}", zone = NepalClock.ZONE)
    public void syncCalendar() {
        List<Integer> years = props.sync().years();
        if (years == null || years.isEmpty()) return;
        for (int year : years) {
            try {
                calendarSync.sync(year);
            } catch (RuntimeException e) {
                // Hook alerting (Slack/email) here: a failed sync means stale holiday data.
                log.error("ALERT: holiday calendar sync failed for BS {}", year, e);
            }
        }
    }

    @Scheduled(cron = "0 */1 * * * *", zone = NepalClock.ZONE)
    public void prepareTomorrowsNotices() {
        LocalDate tomorrow = clock.today().plusDays(1);
        List<Long> holidayIds = drafting.holidayIdsOn(tomorrow);
        log.info("Holiday notices for {}: {} holiday(s)", tomorrow, holidayIds.size());
        holidayIds.forEach(drafting::prepareNoticesAsync);
    }

    /** Evening: retry anything that failed (drafts, late institutions, template drafts) and remind undecided admins. */
    @Scheduled(cron = "${holiday.schedule.remind-evening:0 0 20 * * *}", zone = NepalClock.ZONE)
    public void remindEvening() {
        LocalDate tomorrow = clock.today().plusDays(1);
        List<Long> holidayIds = drafting.holidayIdsOn(tomorrow);
        holidayIds.forEach(drafting::upgradeTemplateDraftsAsync);
        holidayIds.forEach(drafting::prepareNoticesAsync);
        reminders.remindUndecided(tomorrow);
    }

    /** Morning of the holiday: last reminder. */
    @Scheduled(cron = "${holiday.schedule.remind-morning:0 0 6 * * *}", zone = NepalClock.ZONE)
    public void remindMorning() {
        reminders.remindUndecided(clock.today());
    }

    /** Every minute: deliver approved notices that are due (new approvals and retries after backoff). */
    @Scheduled(cron = "${holiday.schedule.publish:0 * * * * *}", zone = NepalClock.ZONE)
    public void publishNotices() {
        publishing.publishDueNotices();
    }

    /** Just after midnight: notices nobody decided on before the date passed become EXPIRED. */
    @Scheduled(cron = "${holiday.schedule.expire:0 30 0 * * *}", zone = NepalClock.ZONE)
    public void expireNotices() {
        expiry.expireOverdueNotices();
    }
}
