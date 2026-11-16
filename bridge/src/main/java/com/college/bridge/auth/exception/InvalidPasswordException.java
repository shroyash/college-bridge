package com.college.bridge.auth.exception;

import com.college.bridge.common.exception.BusinessRuleException;

public class InvalidPasswordException extends BusinessRuleException {
    public InvalidPasswordException(String message) {
        super(message);
    }
}
