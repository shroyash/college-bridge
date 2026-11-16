package com.college.bridge.auth.exception;

public class AccountSuspendedException extends SecurityException {
    public AccountSuspendedException(String message) {
        super(message);
    }
}
