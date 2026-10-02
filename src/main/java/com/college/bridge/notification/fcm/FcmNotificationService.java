package com.college.bridge.notification.fcm;

import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class FcmNotificationService {

    private final FirebaseConfig firebaseConfig;

    public record FcmMulticastBatchResult(
            List<Integer> successfulIndices,
            List<String> unregisteredTokens,
            List<Integer> transientFailureIndices,
            List<Integer> permanentFailureIndices,
            boolean hasTransientFailure
    ) {}

    public void sendToTopic(String topic, String title, String body, Map<String, String> dataPayload) throws Exception {
        if (firebaseConfig.isMockMode()) {
            log.debug("[MOCK FCM] sendToTopic: topic={}, title={}", topic, title);
            return;
        }

        ensureFirebaseInitialized();

        Message.Builder messageBuilder = Message.builder()
                .setTopic(topic)
                .setNotification(com.google.firebase.messaging.Notification.builder()
                        .setTitle(title)
                        .setBody(body)
                        .build());

        if (dataPayload != null && !dataPayload.isEmpty()) {
            messageBuilder.putAllData(dataPayload);
        }

        FirebaseMessaging.getInstance().send(messageBuilder.build());
        log.debug("Sent FCM message to topic: {}", topic);
    }

    public FcmMulticastBatchResult sendToTokens(
            List<String> tokens,
            String title,
            String body,
            Map<String, String> dataPayload) throws Exception {

        if (tokens == null || tokens.isEmpty()) {
            return new FcmMulticastBatchResult(List.of(), List.of(), List.of(), List.of(), false);
        }

        if (firebaseConfig.isMockMode()) {
            log.debug("[MOCK FCM] sendToTokens: count={}, title={}", tokens.size(), title);
            List<Integer> allSuccess = new ArrayList<>();
            for (int i = 0; i < tokens.size(); i++) {
                allSuccess.add(i);
            }
            return new FcmMulticastBatchResult(allSuccess, List.of(), List.of(), List.of(), false);
        }

        ensureFirebaseInitialized();

        MulticastMessage.Builder multicastBuilder = MulticastMessage.builder()
                .addAllTokens(tokens)
                .setNotification(com.google.firebase.messaging.Notification.builder()
                        .setTitle(title)
                        .setBody(body)
                        .build());

        if (dataPayload != null && !dataPayload.isEmpty()) {
            multicastBuilder.putAllData(dataPayload);
        }

        BatchResponse batchResponse = FirebaseMessaging.getInstance().sendEachForMulticast(multicastBuilder.build());

        List<Integer> successfulIndices = new ArrayList<>();
        List<String> unregisteredTokens = new ArrayList<>();
        List<Integer> transientIndices = new ArrayList<>();
        List<Integer> permanentIndices = new ArrayList<>();

        List<SendResponse> responses = batchResponse.getResponses();
        for (int i = 0; i < responses.size(); i++) {
            SendResponse response = responses.get(i);
            if (response.isSuccessful()) {
                successfulIndices.add(i);
            } else {
                FirebaseMessagingException exception = response.getException();
                FcmErrorClassifier.ErrorCategory category = FcmErrorClassifier.classify(exception);

                switch (category) {
                    case UNREGISTERED -> {
                        unregisteredTokens.add(tokens.get(i));
                        permanentIndices.add(i);
                    }
                    case TRANSIENT -> transientIndices.add(i);
                    case PERMANENT -> permanentIndices.add(i);
                }
            }
        }

        boolean hasTransient = !transientIndices.isEmpty();
        log.debug("Multicast result: {} success, {} unregistered, {} transient failures, {} permanent failures",
                successfulIndices.size(), unregisteredTokens.size(), transientIndices.size(), permanentIndices.size());

        return new FcmMulticastBatchResult(
                successfulIndices,
                unregisteredTokens,
                transientIndices,
                permanentIndices,
                hasTransient
        );
    }

    public void subscribeTokensToTopic(List<String> tokens, String topic) {
        if (tokens == null || tokens.isEmpty()) {
            return;
        }

        if (firebaseConfig.isMockMode()) {
            log.debug("[MOCK FCM] Subscribing {} tokens to topic: {}", tokens.size(), topic);
            return;
        }

        ensureFirebaseInitialized();

        try {
            // Firebase limits subscribeToTopic to 1000 tokens per call
            int batchSize = 1000;
            for (int i = 0; i < tokens.size(); i += batchSize) {
                List<String> batch = tokens.subList(i, Math.min(i + batchSize, tokens.size()));
                TopicManagementResponse response = FirebaseMessaging.getInstance().subscribeToTopic(batch, topic);
                log.debug("Subscribed batch of {} tokens to {}: {} successes, {} failures",
                        batch.size(), topic, response.getSuccessCount(), response.getFailureCount());
            }
        } catch (Exception e) {
            log.warn("Failed to subscribe tokens to topic {}: {}", topic, e.getMessage());
        }
    }

    public void unsubscribeTokensFromTopic(List<String> tokens, String topic) {
        if (tokens == null || tokens.isEmpty()) {
            return;
        }

        if (firebaseConfig.isMockMode()) {
            log.debug("[MOCK FCM] Unsubscribing {} tokens from topic: {}", tokens.size(), topic);
            return;
        }

        ensureFirebaseInitialized();

        try {
            int batchSize = 1000;
            for (int i = 0; i < tokens.size(); i += batchSize) {
                List<String> batch = tokens.subList(i, Math.min(i + batchSize, tokens.size()));
                TopicManagementResponse response = FirebaseMessaging.getInstance().unsubscribeFromTopic(batch, topic);
                log.debug("Unsubscribed batch of {} tokens from {}: {} successes, {} failures",
                        batch.size(), topic, response.getSuccessCount(), response.getFailureCount());
            }
        } catch (Exception e) {
            log.warn("Failed to unsubscribe tokens from topic {}: {}", topic, e.getMessage());
        }
    }

    private void ensureFirebaseInitialized() {
        if (FirebaseApp.getApps().isEmpty()) {
            throw new IllegalStateException("Firebase is not initialized and mock mode is false");
        }
    }
}
