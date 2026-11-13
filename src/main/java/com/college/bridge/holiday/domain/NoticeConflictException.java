package com.college.bridge.holiday.domain;

/** The requested change is not allowed in the notice's current state (e.g. already approved). */
public class NoticeConflictException extends RuntimeException {
    public NoticeConflictException(String message) { super(message); }
}
