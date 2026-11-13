package com.college.bridge.holiday.infrastructure.messaging;

import com.college.bridge.holiday.application.port.AdminDirectory;
import com.college.bridge.holiday.application.port.AdminDirectory.AdminDevice;
import com.college.bridge.notification.exception.FcmSendException;
import com.college.bridge.notification.fcm.FcmNotificationService;
import com.college.bridge.notification.fcm.FcmNotificationService.FcmMulticastBatchResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Token-based push to the admins of ONE institution. Token-based (not topic-based) because we get a result
 * per device: transient failures are retried and dead tokens are removed.
 */
@Component
@Slf4j
@RequiredArgsConstructor
class AdminPushSender {

    private static final int FCM_MULTICAST_LIMIT = 500;
    private static final int MAX_ATTEMPTS = 3;
    private static final long BACKOFF_MILLIS = 2000;

    private final FcmNotificationService fcm;
    private final AdminDirectory admins;

    void send(Long institutionId, String title, String body, Map<String, String> data) {
        List<String> tokens = admins.activeDevices(institutionId).stream()
                .map(AdminDevice::token)
                .filter(token -> token != null && !token.isBlank())
                .distinct()
                .toList();
        if (tokens.isEmpty()) {
            log.warn("Institution {} has no admin device tokens; admins will see the notice in the app's pending list",
                    institutionId);
            return;
        }

        Set<String> deadTokens = new HashSet<>();
        for (int from = 0; from < tokens.size(); from += FCM_MULTICAST_LIMIT) {
            List<String> chunk = new ArrayList<>(tokens.subList(from, Math.min(from + FCM_MULTICAST_LIMIT, tokens.size())));
            deliver(chunk, title, body, data, deadTokens);
        }
        if (!deadTokens.isEmpty()) {
            admins.forget(deadTokens);
            log.info("Removed {} unregistered admin device tokens", deadTokens.size());
        }
    }

    /** Sends one chunk, retrying only the devices that failed temporarily. */
    private void deliver(List<String> chunk, String title, String body, Map<String, String> data, Set<String> deadTokens) {
        List<String> pending = chunk;
        for (int attempt = 1; attempt <= MAX_ATTEMPTS && !pending.isEmpty(); attempt++) {
            try {
                FcmMulticastBatchResult result = fcm.sendToTokens(pending, title, body, data);
                deadTokens.addAll(result.unregisteredTokens());
                if (!result.permanentFailureIndices().isEmpty()) {
                    log.warn("{} admin devices failed permanently", result.permanentFailureIndices().size());
                }
                List<String> sentJustNow = pending;
                pending = new ArrayList<>(result.transientFailureIndices().stream().map(sentJustNow::get).toList());
            } catch (FcmSendException e) {
                log.warn("Admin push attempt {}/{} failed: {}", attempt, MAX_ATTEMPTS, e.getMessage());
            }
            if (!pending.isEmpty() && attempt < MAX_ATTEMPTS) {
                pause(BACKOFF_MILLIS * attempt);
            }
        }
        if (!pending.isEmpty()) {
            log.error("{} admin devices still unreachable after {} attempts (the in-app pending list is the fallback)",
                    pending.size(), MAX_ATTEMPTS);
        }
    }

    private static void pause(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
