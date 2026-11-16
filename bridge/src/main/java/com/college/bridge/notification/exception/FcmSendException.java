package com.college.bridge.notification.exception;

public class FcmSendException extends FcmException {
    public FcmSendException(String message, Throwable cause, boolean retryable) {
        super(message, cause, retryable);
    }
}