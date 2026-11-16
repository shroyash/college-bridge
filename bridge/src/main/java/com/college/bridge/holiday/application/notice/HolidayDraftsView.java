package com.college.bridge.holiday.application.notice;

import com.college.bridge.holiday.domain.HolidayScope;
import com.college.bridge.holiday.domain.NoticeStatus;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/** Super-admin inspection of one holiday: shared drafts and how many institutions are in each state. */
public record HolidayDraftsView(Long holidayId, String holidayName, LocalDate date, String dateBs,
                                HolidayScope scope, List<DraftView> drafts,
                                Map<NoticeStatus, Long> institutionsByStatus) {}
