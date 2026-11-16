package com.college.bridge.holiday.domain;

/**
 * Life cycle of ONE institution's notice for ONE holiday.
 * AWAITING_DECISION -> APPROVED -> PUBLISHING -> PUBLISHED   (approved = official; the push is decoupled)
 * PUBLISHING returns to APPROVED on a retryable failure and ends in FAILED after too many attempts.
 * AWAITING_DECISION -> REJECTED (admin declined) or EXPIRED (nobody acted before the date passed).
 */
public enum NoticeStatus {
    AWAITING_DECISION,
    APPROVED,
    PUBLISHING,
    PUBLISHED,
    FAILED,
    REJECTED,
    EXPIRED
}
