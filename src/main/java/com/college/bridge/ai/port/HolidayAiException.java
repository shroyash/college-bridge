package com.college.bridge.holiday.port;

/** Any failure of the AI step. {@code retryable} tells callers whether trying again can help. */
public class HolidayAiException extends RuntimeException {

    private final boolean retryable;

    public HolidayAiException(String message, boolean retryable) {
        super(message);
        this.retryable = retryable;
    }

    public HolidayAiException(String message, Throwable cause, boolean retryable) {
        super(message, cause);
        this.retryable = retryable;
    }

    public boolean isRetryable() { return retryable; }
}
