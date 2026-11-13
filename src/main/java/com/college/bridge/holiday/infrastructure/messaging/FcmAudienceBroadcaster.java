package com.college.bridge.holiday.infrastructure.messaging;

import com.college.bridge.holiday.application.port.AudienceBroadcaster;
import com.college.bridge.holiday.application.port.AudienceTopics;
import com.college.bridge.holiday.application.port.BroadcastFailedException;
import com.college.bridge.notification.exception.FcmSendException;
import com.college.bridge.notification.fcm.FcmNotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Adapter: pushes an approved notice to the institution's own topics (never another institution's).
 * Topic-based because the audience is large and per-device results are not needed.
 * Delivery is at-least-once: if students succeed but teachers fail, a retry may re-send to students.
 */
@Component
@Slf4j
@RequiredArgsConstructor
class FcmAudienceBroadcaster implements AudienceBroadcaster {

    private static final int MAX_ATTEMPTS = 3;
    private static final long BACKOFF_MILLIS = 2000;
    private static final int MAX_TITLE_LENGTH = 120;
    private static final int MAX_BODY_PREVIEW_LENGTH = 200;

    private final FcmNotificationService fcm;

    @Override
    public void broadcast(Broadcast broadcast) {
        String title = abbreviate(broadcast.institutionName() + ": " + broadcast.title(), MAX_TITLE_LENGTH);
        String body = abbreviate(broadcast.body(), MAX_BODY_PREVIEW_LENGTH); // full text is read in the app
        Map<String, String> data = Map.of(
                NotificationTypes.KEY_TYPE, NotificationTypes.HOLIDAY_NOTICE,
                NotificationTypes.KEY_HOLIDAY_ID, String.valueOf(broadcast.holidayId()));

        List<String> failedTopics = new ArrayList<>();
        if (broadcast.students()) {
            sendWithRetry(AudienceTopics.students(broadcast.institutionId()), title, body, data, failedTopics);
        }
        if (broadcast.teachers()) {
            sendWithRetry(AudienceTopics.teachers(broadcast.institutionId()), title, body, data, failedTopics);
        }
        if (!failedTopics.isEmpty()) {
            throw new BroadcastFailedException(
                    "Could not broadcast holiday notice " + broadcast.holidayId() + " to " + failedTopics, null);
        }
    }

    private void sendWithRetry(String topic, String title, String body, Map<String, String> data,
                               List<String> failedTopics) {
        for (int attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
            try {
                fcm.sendToTopic(topic, title, body, data);
                return;
            } catch (FcmSendException e) {
                log.warn("Broadcast to {} attempt {}/{} failed: {} (cause: {})",
                        topic, attempt, MAX_ATTEMPTS, e.getMessage(),
                        e.getCause() != null ? e.getCause().getMessage() : "none", e);
                if (attempt < MAX_ATTEMPTS) {
                    pause(BACKOFF_MILLIS * attempt);
                }
            }
        }
        failedTopics.add(topic);
    }

    private static String abbreviate(String text, int maxLength) {
        if (text == null) return "";
        return text.length() <= maxLength ? text : text.substring(0, maxLength - 1) + "\u2026";
    }

    private static void pause(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
