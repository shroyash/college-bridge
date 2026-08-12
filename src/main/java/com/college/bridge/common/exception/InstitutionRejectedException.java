package com.college.bridge.common.exception;

import lombok.Getter;

@Getter
public class InstitutionRejectedException extends RuntimeException {

    private final String rejectionReason;

    public InstitutionRejectedException(String message, String rejectionReason) {
        super(message);
        this.rejectionReason = rejectionReason;
    }

    public InstitutionRejectedException(String message) {
        this(message, null);
    }
}
