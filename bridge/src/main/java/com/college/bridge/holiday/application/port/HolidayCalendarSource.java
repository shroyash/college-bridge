package com.college.bridge.holiday.application.port;

import com.college.bridge.holiday.domain.HolidayScope;

import java.time.LocalDate;
import java.util.List;

/** Outbound port: where the list of public holidays comes from. */
public interface HolidayCalendarSource {

    /** @throws CalendarUnavailableException when the calendar cannot be read or is empty */
    List<CalendarEntry> fetchYear(int bsYear);

    record CalendarEntry(String name, LocalDate dateAd, String dateBs, HolidayScope scope) {}
}
