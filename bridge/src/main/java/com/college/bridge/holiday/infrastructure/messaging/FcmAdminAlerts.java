package com.college.bridge.holiday.infrastructure.messaging;

import com.college.bridge.holiday.application.port.AdminAlerts;
import com.college.bridge.holiday.domain.PublicHoliday;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Map;

/**
 * Adapter: turns "this institution's admins must act" into push messages. The push carries only a navigation
 * hint (type + holiday id): the app must reload the real data from the API, never trust the payload.
 */
@Component
@RequiredArgsConstructor
class FcmAdminAlerts implements AdminAlerts {

    private final AdminPushSender sender;

    @Override
    public void approvalRequested(Long institutionId, PublicHoliday holiday, boolean reminder) {
        String title = reminder ? "Reminder: holiday notice needs a decision" : "Holiday notice drafts are ready";
        String body = holiday.getName() + " on " + holiday.getDateAd() + ". Tap to review and approve.";
        sender.send(institutionId, title, body, data(NotificationTypes.APPROVAL_REQUESTED, holiday));
    }

    @Override
    public void publishingFailed(Long institutionId, PublicHoliday holiday) {
        sender.send(institutionId, "Holiday notice could not be pushed",
                "The approved notice for " + holiday.getName()
                        + " is saved and visible in the app, but the push notification failed.",
                data(NotificationTypes.PUBLISH_FAILED, holiday));
    }

    private static Map<String, String> data(String type, PublicHoliday holiday) {
        return Map.of(NotificationTypes.KEY_TYPE, type,
                NotificationTypes.KEY_HOLIDAY_ID, String.valueOf(holiday.getId()));
    }
}
