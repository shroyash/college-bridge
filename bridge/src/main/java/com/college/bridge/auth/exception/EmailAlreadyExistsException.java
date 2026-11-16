package com.college.bridge.auth.exception;

import com.college.bridge.common.exception.DuplicateResourceException;

public class EmailAlreadyExistsException extends DuplicateResourceException {
    public EmailAlreadyExistsException(String message) {
        super(message);
    }
}
