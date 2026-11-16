package com.college.bridge.common.exception;

public class AccountPendingVerificationException extends RuntimeException {
    public AccountPendingVerificationException(String message) {
        super(message);
    }
}
