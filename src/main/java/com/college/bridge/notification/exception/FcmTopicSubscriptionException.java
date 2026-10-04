package com.college.bridge.notification.exception;

public class FcmTopicSubscriptionException extends FcmException {
    public FcmTopicSubscriptionException(String message, Throwable cause, boolean retryable) {
        super(message, cause, retryable);
    }
}