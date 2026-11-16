package com.college.bridge.holiday.application.calendar;

import com.college.bridge.holiday.application.port.CalendarUnavailableException;
import com.college.bridge.holiday.application.port.HolidayCalendarSource;
import com.college.bridge.holiday.application.port.HolidayCalendarSource.CalendarEntry;
import com.college.bridge.holiday.config.HolidayProperties;
import com.college.bridge.holiday.config.NepalClock;
import com.college.bridge.holiday.domain.InstitutionNoticeRepository;
import com.college.bridge.holiday.domain.NoticeDraftRepository;
import com.college.bridge.holiday.domain.PublicHoliday;
import com.college.bridge.holiday.domain.PublicHolidayRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.Instant;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Use case: make the stored holidays of one BS year match the national calendar.
 * The network call happens OUTSIDE any database transaction; only the writes are transactional.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class HolidayCalendarSyncService {

    private final HolidayCalendarSource calendar;
    private final PublicHolidayRepository holidays;
    private final NoticeDraftRepository drafts;
    private final InstitutionNoticeRepository notices;
    private final TransactionTemplate transaction;
    private final HolidayProperties props;
    private final NepalClock clock;

    public int sync(int bsYear) {
        List<CalendarEntry> entries = calendar.fetchYear(bsYear);
        if (entries.isEmpty()) {
            // Never treat "no data" as "no holidays": it would wipe a whole year.
            throw new CalendarUnavailableException("Calendar returned no holidays for BS " + bsYear);
        }
        Instant fetchedAt = clock.instantNow();
        String type = props.api().type();

        Integer stored = transaction.execute(status -> apply(bsYear, entries, type, fetchedAt));
        return stored == null ? 0 : stored;
    }

    private int apply(int bsYear, List<CalendarEntry> entries, String type, Instant fetchedAt) {
        Set<Long> keptIds = new HashSet<>();
        for (CalendarEntry entry : entries) {
            PublicHoliday holiday = holidays.findByDateAdAndName(entry.dateAd(), entry.name())
                    .map(existing -> {
                        existing.refresh(entry.dateBs(), type, entry.scope(), fetchedAt);
                        return existing;
                    })
                    .orElseGet(() -> PublicHoliday.create(
                            entry.dateAd(), entry.dateBs(), entry.name(), type, entry.scope(), fetchedAt));
            keptIds.add(holidays.save(holiday).getId());
        }
        removeHolidaysNoLongerListed(bsYear, keptIds);
        log.info("Holiday sync for BS {} finished: {} holidays", bsYear, keptIds.size());
        return keptIds.size();
    }

    /** A festival that moved or was cancelled must not trigger notices for the old date. */
    private void removeHolidaysNoLongerListed(int bsYear, Set<Long> keptIds) {
        for (PublicHoliday stored : holidays.findByDateBsStartingWith(bsYear + "-")) {
            if (keptIds.contains(stored.getId())) continue;
            if (notices.existsByHolidayId(stored.getId())) {
                log.warn("Holiday '{}' ({}) is no longer in the calendar but institutions already have notices; keeping it",
                        stored.getName(), stored.getDateAd());
            } else {
                drafts.deleteByHolidayId(stored.getId());
                holidays.delete(stored);
                log.info("Removed holiday no longer in the calendar: '{}' ({})", stored.getName(), stored.getDateAd());
            }
        }
    }
}
