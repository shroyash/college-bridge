package com.college.bridge.holiday.infrastructure.messaging;

/** The contract with the mobile app: data keys and type values inside every push. Change only together with the app. */
final class NotificationTypes {

    static final String KEY_TYPE = "type";
    static final String KEY_HOLIDAY_ID = "holiday_id";

    static final String APPROVAL_REQUESTED = "HOLIDAY_APPROVAL";
    static final String PUBLISH_FAILED = "HOLIDAY_PUBLISH_FAILED";
    static final String HOLIDAY_NOTICE = "HOLIDAY_NOTICE";

    private NotificationTypes() {}
}
