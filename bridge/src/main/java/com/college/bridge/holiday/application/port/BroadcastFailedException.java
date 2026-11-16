package com.college.bridge.holiday.application.port;

public class BroadcastFailedException extends RuntimeException {
    public BroadcastFailedException(String message, Throwable cause) { super(message, cause); }
}
