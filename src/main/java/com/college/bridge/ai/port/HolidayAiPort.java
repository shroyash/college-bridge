package com.college.bridge.holiday.port;

import java.time.LocalDate;

/** The only thing the holiday code knows about AI. Swap the implementation without touching business logic. */
public interface HolidayAiPort {

    /** One call returning both notices. @throws HolidayAiException on any failure */
    GeneratedNotices generate(HolidayContext ctx);

    record HolidayContext(String holidayName, LocalDate dateAd, String dateBs, String language) {}

    record Notice(String title, String body) {}

    record GeneratedNotices(Notice holiday, Notice open, String model) {}
}
