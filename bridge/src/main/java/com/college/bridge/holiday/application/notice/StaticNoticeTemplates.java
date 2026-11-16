package com.college.bridge.holiday.application.notice;

import com.college.bridge.holiday.application.port.NoticeWriter.WrittenNotice;
import com.college.bridge.holiday.application.port.NoticeWriter.WrittenNotices;
import com.college.bridge.holiday.domain.DraftOrigin;
import com.college.bridge.holiday.domain.PublicHoliday;

import java.time.format.DateTimeFormatter;
import java.util.Locale;

/** Fixed wording used when the AI cannot deliver, so the approval flow never stops. Generic and date-explicit. */
public final class StaticNoticeTemplates {

    static final String MODEL = "template";

    private static final DateTimeFormatter DATE_FORMAT =
            DateTimeFormatter.ofPattern("EEEE, d MMMM yyyy", Locale.ENGLISH);

    private StaticNoticeTemplates() {}

    public static WrittenNotices forHoliday(PublicHoliday holiday) {
        String date = holiday.getDateAd().format(DATE_FORMAT) + " (" + holiday.getDateBs() + " BS)";
        WrittenNotice closed = new WrittenNotice(
                "Holiday Notice: " + holiday.getName(),
                "This is to inform all students, parents and staff that the college will remain closed on "
                        + date + " on account of " + holiday.getName()
                        + ". Regular classes will resume on the next working day.");
        WrittenNotice open = new WrittenNotice(
                "Regular Classes on " + holiday.getName(),
                "Although " + date + " is a public holiday (" + holiday.getName()
                        + "), the college will remain open and all classes will run as usual.");
        return new WrittenNotices(closed, open, DraftOrigin.TEMPLATE, MODEL);
    }
}
