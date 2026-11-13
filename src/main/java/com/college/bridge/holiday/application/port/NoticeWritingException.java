package com.college.bridge.holiday.application.port;

/** Failure to write notices. {@code retryable} separates "try again" (timeouts, 5xx) from "never works" (bad key). */
public class NoticeWritingException extends RuntimeException {

    private final boolean retryable;

    public NoticeWritingException(String message, boolean retryable) {
        super(message);
        this.retryable = retryable;
    }

    public NoticeWritingException(String message, Throwable cause, boolean retryable) {
        super(message, cause);
        this.retryable = retryable;
    }

    public boolean isRetryable() { return retryable; }
}
