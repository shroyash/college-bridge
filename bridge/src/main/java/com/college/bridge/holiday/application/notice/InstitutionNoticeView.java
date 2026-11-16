package com.college.bridge.holiday.application.notice;

import com.college.bridge.holiday.domain.NoticeStatus;
import com.college.bridge.holiday.domain.NoticeVariant;

import java.time.LocalDate;
import java.util.List;

/** What an institution admin sees for one holiday: the shared drafts plus this institution's own state. */
public record InstitutionNoticeView(Long holidayId, String holidayName, LocalDate date, String dateBs,
                                    NoticeStatus status, NoticeVariant approvedVariant,
                                    String finalTitle, String finalBody, List<DraftView> drafts) {}
