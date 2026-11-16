package com.college.bridge.holiday.application.port;

import com.college.bridge.holiday.domain.DraftOrigin;

import java.time.LocalDate;

/**
 * Outbound port: something that can write the CLOSED and OPEN draft for a holiday (today: Gemini).
 * The request has no institution: drafts are shared, so they never name a specific college.
 */
public interface NoticeWriter {

    /** @throws NoticeWritingException on any failure; its flag says whether a retry can help */
    WrittenNotices write(NoticeRequest request);

    record NoticeRequest(String holidayName, LocalDate dateAd, String dateBs, String language) {}

    record WrittenNotice(String title, String body) {}

    record WrittenNotices(WrittenNotice closed, WrittenNotice open, DraftOrigin origin, String model) {}
}
