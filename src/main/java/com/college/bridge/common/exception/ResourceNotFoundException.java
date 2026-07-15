package com.college.bridge.common.exception;

/**
 * Thrown when a requested resource cannot be found in the database.
 * Maps to HTTP 404 Not Found in the {@code GlobalExceptionHandler}.
 */
public class ResourceNotFoundException extends RuntimeException {

    public ResourceNotFoundException(String message) {
        super(message);
    }

    public ResourceNotFoundException(String resourceName, Long id) {
        super(resourceName + " not found with id: " + id);
    }

    public ResourceNotFoundException(String resourceName, String field, Object value) {
        super(resourceName + " not found with " + field + ": " + value);
    }
}
