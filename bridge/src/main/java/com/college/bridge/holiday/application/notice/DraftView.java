package com.college.bridge.holiday.application.notice;

import com.college.bridge.holiday.domain.DraftOrigin;
import com.college.bridge.holiday.domain.NoticeVariant;

/** A shared AI draft as shown to admins. */
public record DraftView(NoticeVariant variant, String title, String body, DraftOrigin origin, String model) {}
