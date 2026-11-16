package com.college.bridge.holiday.application.port;

public class CalendarUnavailableException extends RuntimeException {
    public CalendarUnavailableException(String message) { super(message); }

    public CalendarUnavailableException(String message, Throwable cause) { super(message, cause); }
}
