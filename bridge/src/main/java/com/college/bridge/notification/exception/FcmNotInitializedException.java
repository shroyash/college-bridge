package com.college.bridge.notification.exception;

public class FcmNotInitializedException extends FcmException {
    public FcmNotInitializedException() {
        super("Firebase is not initialized and mock mode is false", null, false);
    }
}