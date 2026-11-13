package com.college.bridge.holiday.domain;

/** The request content is not acceptable (e.g. text is empty after cleaning). */
public class NoticeInvalidException extends RuntimeException {
    public NoticeInvalidException(String message) { super(message); }
}
