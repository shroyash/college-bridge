package com.college.bridge.holiday.application.notice;

import com.college.bridge.holiday.domain.NoticeVariant;

import java.time.Instant;
import java.time.LocalDate;

/** An approved (official) notice, as read by anyone in the institution. */
public record OfficialNoticeView(Long holidayId, String holidayName, LocalDate date, NoticeVariant variant,
                                 String title, String body, Instant approvedAt) {}
