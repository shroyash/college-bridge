package com.college.bridge.common.exception;

/**
 * Thrown when a request violates a domain business rule
 * (e.g., submitting a verification request when one already exists).
 * Maps to HTTP 422 Unprocessable Entity in the {@code GlobalExceptionHandler}.
 */
public class BusinessRuleException extends RuntimeException {

    public BusinessRuleException(String message) {
        super(message);
    }
}
