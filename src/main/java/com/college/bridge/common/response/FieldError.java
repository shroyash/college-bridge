package com.college.bridge.common.response;

/**
 * Represents a single field-level validation or business rule error
 * included in the {@code errors} array of an {@link ApiResponse}.
 *
 * <pre>
 * {
 *   "field": "email",
 *   "message": "Email is already registered."
 * }
 * </pre>
 */
public record FieldError(String field, String message) {
}
