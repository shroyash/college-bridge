package com.college.bridge.common.exception;

/**
 * Exception thrown when a requested record does not belong to the current active tenant (institution).
 * Mapped to HTTP 404 Not Found by GlobalExceptionHandler to prevent data enumeration attacks across tenants.
 */
public class TenantMismatchException extends RuntimeException {

    public TenantMismatchException(String message) {
        super(message);
    }
}
