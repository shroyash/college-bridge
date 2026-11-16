package com.college.bridge.auth.exception;

import com.college.bridge.common.exception.BusinessRuleException;

public class InvalidRoleException extends BusinessRuleException {
    public InvalidRoleException(String message) {
        super(message);
    }
}
