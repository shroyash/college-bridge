package com.college.bridge.holiday.application.notice;

/** The AI could not produce new drafts right now (existing drafts are kept). */
public class DraftingUnavailableException extends RuntimeException {
    public DraftingUnavailableException(String message) { super(message); }
}
