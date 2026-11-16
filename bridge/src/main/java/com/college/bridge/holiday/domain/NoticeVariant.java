package com.college.bridge.holiday.domain;

/** The two notices written for every holiday; an admin approves exactly one. */
public enum NoticeVariant {
    /** The institution is closed for the holiday. */
    CLOSED,
    /** It is a public holiday, but the institution stays open. */
    OPEN
}
