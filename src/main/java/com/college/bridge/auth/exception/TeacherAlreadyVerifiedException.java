package com.college.bridge.auth.exception;

import com.college.bridge.common.exception.BusinessRuleException;

public class TeacherAlreadyVerifiedException extends BusinessRuleException {
    public TeacherAlreadyVerifiedException(String message) {
        super(message);
    }
}
