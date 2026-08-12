package com.college.bridge.common.exception;

import com.college.bridge.academic.exception.TeacherAssignmentAlreadyExistsException;
import com.college.bridge.auth.exception.AccountSuspendedException;
import com.college.bridge.common.response.ApiResponse;
import com.college.bridge.common.response.FieldError;
import jakarta.persistence.EntityNotFoundException;
import jakarta.validation.ConstraintViolationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    /**
     * Handles DTO field validation errors (@Valid on @RequestBody).
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleValidationException(MethodArgumentNotValidException ex) {
        List<FieldError> errors = ex.getBindingResult()
                .getFieldErrors()
                .stream()
                .map(error -> FieldError.builder()
                        .field(error.getField())
                        .message(error.getDefaultMessage())
                        .build())
                .toList();

        return ResponseEntity.badRequest()
                .body(ApiResponse.error("Validation failed.", errors));
    }

    /**
     * Handles URL parameter and path variable validation errors (@Validated).
     */
    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ApiResponse<Void>> handleConstraintViolation(ConstraintViolationException ex) {
        List<FieldError> errors = ex.getConstraintViolations()
                .stream()
                .map(violation -> FieldError.builder()
                        .field(violation.getPropertyPath().toString())
                        .message(violation.getMessage())
                        .build())
                .toList();

        return ResponseEntity.badRequest()
                .body(ApiResponse.error("Validation failed.", errors));
    }

    /**
     * Handles missing entities or resources.
     */
    @ExceptionHandler({EntityNotFoundException.class, ResourceNotFoundException.class})
    public ResponseEntity<ApiResponse<Void>> handleEntityNotFound(RuntimeException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.error(ex.getMessage()));
    }

    /**
     * Handles cross-tenant access attempts or tenant mismatch errors (mapped to 404 Not Found).
     */
    @ExceptionHandler(TenantMismatchException.class)
    public ResponseEntity<ApiResponse<Void>> handleTenantMismatch(TenantMismatchException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.error(ex.getMessage()));
    }

    @ExceptionHandler(TeacherAssignmentAlreadyExistsException.class)
    public ResponseEntity<ApiResponse<Void>> handleTeacherAssignmentAlreadyExists(TeacherAssignmentAlreadyExistsException ex) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(ApiResponse.error(ex.getMessage()));
    }

    /**
     * Handles institution & user status rejection exceptions during login / access.
     */
    @ExceptionHandler({
            InstitutionPendingException.class,
            InstitutionRejectedException.class,
            InstitutionSuspendedException.class,
            AccountPendingVerificationException.class,
            AccountSuspendedException.class
    })
    public ResponseEntity<ApiResponse<Void>> handleStatusExceptions(RuntimeException ex) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(ApiResponse.error(ex.getMessage()));
    }

    /**
     * Handles malformed JSON payloads or invalid request body formatting.
     */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiResponse<Void>> handleHttpMessageNotReadable(HttpMessageNotReadableException ex) {
        return ResponseEntity.badRequest()
                .body(ApiResponse.error("Malformed JSON request or invalid request body format."));
    }

    /**
     * Handles method argument type mismatch (e.g., passing a string where an integer ID is expected).
     */
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ApiResponse<Void>> handleTypeMismatch(MethodArgumentTypeMismatchException ex) {
        String message = String.format("Parameter '%s' should be of type %s",
                ex.getName(),
                ex.getRequiredType() != null ? ex.getRequiredType().getSimpleName() : "unknown");
        return ResponseEntity.badRequest().body(ApiResponse.error(message));
    }

    /**
     * Handles invalid business logic parameters.
     */
    @ExceptionHandler({IllegalArgumentException.class, BusinessRuleException.class, DuplicateResourceException.class})
    public ResponseEntity<ApiResponse<Void>> handleBusinessRuleExceptions(RuntimeException ex) {
        return ResponseEntity.badRequest()
                .body(ApiResponse.error(ex.getMessage()));
    }

    /**
     * Handles HTTP method not allowed (e.g., sending POST to a GET-only endpoint).
     */
    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ApiResponse<Void>> handleMethodNotSupported(HttpRequestMethodNotSupportedException ex) {
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED)
                .body(ApiResponse.error(ex.getMessage()));
    }

    /**
     * Handles unauthorized access attempts.
     */
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResponse<Void>> handleAccessDenied(AccessDeniedException ex) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(ApiResponse.error("You do not have permission to perform this action."));
    }

    /**
     * Handles Spring's ResponseStatusException (including TenantMismatchException).
     * Relays the HTTP status embedded in the exception.
     */
    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<ApiResponse<Void>> handleResponseStatus(ResponseStatusException ex) {
        return ResponseEntity.status(ex.getStatusCode())
                .body(ApiResponse.error(ex.getReason() != null ? ex.getReason() : ex.getMessage()));
    }

    /**
     * Fallback handler for unhandled exceptions.
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleUnhandledException(Exception ex) {
        log.error("Unhandled exception caught in GlobalExceptionHandler", ex);

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("An unexpected error occurred. Please try again later."));
    }
}