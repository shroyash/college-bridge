package com.college.bridge.auth.exception;

import com.college.bridge.common.exception.BusinessRuleException;

public class OtpExpiredException extends BusinessRuleException {
    public OtpExpiredException(String message) {
        super(message);
    }
}
