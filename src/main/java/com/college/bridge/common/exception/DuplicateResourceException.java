package com.college.bridge.common.exception;

/**
 * Thrown when attempting to create a resource that already exists
 * (e.g., registering with an email that is already in use).
 * Maps to HTTP 409 Conflict in the {@code GlobalExceptionHandler}.
 */
public class DuplicateResourceException extends RuntimeException {

    public DuplicateResourceException(String message) {
        super(message);
    }

    public DuplicateResourceException(String resourceName, String field, Object value) {
        super(resourceName + " already exists with " + field + ": " + value);
    }
}
