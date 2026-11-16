package com.college.bridge.auth.exception;

import com.college.bridge.common.exception.BusinessRuleException;

public class OtpInvalidException extends BusinessRuleException {
    public OtpInvalidException(String message) {
        super(message);
    }
}
