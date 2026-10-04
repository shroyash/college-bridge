package com.college.bridge.notification.exception;

public class FcmException extends RuntimeException {
    private final boolean retryable;

    public FcmException(String message, Throwable cause, boolean retryable) {
        super(message, cause);
        this.retryable = retryable;
    }

    public boolean isRetryable() { return retryable; }
}