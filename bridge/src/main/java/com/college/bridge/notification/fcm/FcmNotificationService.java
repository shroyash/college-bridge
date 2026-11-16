package com.college.bridge.notification.fcm;

import com.college.bridge.notification.exception.FcmNotInitializedException;
import com.college.bridge.notification.exception.FcmSendException;
import com.college.bridge.notification.exception.FcmTopicSubscriptionException;
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

    private static final int MAX_MULTICAST_TOKENS = 500;   // sendEachForMulticast limit
    private static final int TOPIC_BATCH_SIZE = 1000;      // subscribe/unsubscribe limit

    private final FirebaseConfig firebaseConfig;

    public record FcmMulticastBatchResult(
            List<Integer> successfulIndices,
            List<String> unregisteredTokens,
            List<Integer> transientFailureIndices,
            List<Integer> permanentFailureIndices
    ) {}

    @FunctionalInterface
    private interface TopicCall {
        TopicManagementResponse run(List<String> batch) throws FirebaseMessagingException;
    }


    public void sendToTopic(String topic, String title, String body, Map<String, String> data) {
        if (topic == null || topic.isBlank()) {
            throw new IllegalArgumentException("Topic must not be blank");
        }
        if (firebaseConfig.isMockMode()) {
            log.debug("[MOCK FCM] sendToTopic: topic={}", topic);
            return;
        }
        ensureFirebaseInitialized();

        Message.Builder builder = Message.builder()
                .setTopic(topic)
                .setNotification(com.google.firebase.messaging.Notification.builder()
                        .setTitle(title).setBody(body).build());
        if (data != null && !data.isEmpty()) builder.putAllData(data);

        try {
            FirebaseMessaging.getInstance().send(builder.build());
        } catch (FirebaseMessagingException e) {
            throw new FcmSendException("Failed to send to topic " + topic, e, isRetryable(e));
        }
    }


    public FcmMulticastBatchResult sendToTokens(List<String> tokens, String title, String body,
                                                Map<String, String> data) {
        if (tokens == null || tokens.isEmpty()) {
            return new FcmMulticastBatchResult(List.of(), List.of(), List.of(), List.of());
        }
        if (tokens.size() > MAX_MULTICAST_TOKENS) {
            throw new IllegalArgumentException("Max " + MAX_MULTICAST_TOKENS + " tokens per call");
        }

        if (tokens.stream().anyMatch(t -> t == null || t.isBlank())) {
            throw new IllegalArgumentException("Token list contains null or blank values");
        }

        if (firebaseConfig.isMockMode()) {
            log.debug("[MOCK FCM] sendToTokens: count={}", tokens.size());
            List<Integer> all = new ArrayList<>();
            for (int i = 0; i < tokens.size(); i++) all.add(i);
            return new FcmMulticastBatchResult(all, List.of(), List.of(), List.of());
        }
        ensureFirebaseInitialized();

        MulticastMessage.Builder builder = MulticastMessage.builder()
                .addAllTokens(tokens)
                .setNotification(com.google.firebase.messaging.Notification.builder()
                        .setTitle(title).setBody(body).build());
        if (data != null && !data.isEmpty()) builder.putAllData(data);

        BatchResponse batchResponse;
        try {
            batchResponse = FirebaseMessaging.getInstance().sendEachForMulticast(builder.build());
        } catch (FirebaseMessagingException e) {
            throw new FcmSendException("Multicast send failed", e, isRetryable(e));
        }
        return classifyResponses(tokens, batchResponse);
    }

    private FcmMulticastBatchResult classifyResponses(List<String> tokens, BatchResponse batchResponse) {
        List<Integer> successful = new ArrayList<>();
        List<String> unregistered = new ArrayList<>();
        List<Integer> transientFailures = new ArrayList<>();
        List<Integer> permanentFailures = new ArrayList<>();

        List<SendResponse> responses = batchResponse.getResponses();
        for (int i = 0; i < responses.size(); i++) {
            SendResponse response = responses.get(i);
            if (response.isSuccessful()) {
                successful.add(i);
                continue;
            }
            switch (FcmErrorClassifier.classify(response.getException())) {
                case UNREGISTERED -> {
                    unregistered.add(tokens.get(i));
                    permanentFailures.add(i);
                }
                case TRANSIENT -> transientFailures.add(i);
                case PERMANENT -> permanentFailures.add(i);
            }
        }
        log.debug("Multicast result: {} success, {} unregistered, {} transient, {} permanent",
                successful.size(), unregistered.size(), transientFailures.size(), permanentFailures.size());
        return new FcmMulticastBatchResult(successful, unregistered, transientFailures, permanentFailures);
    }


    public void subscribeTokensToTopic(List<String> tokens, String topic) {
        runTopicOperation(tokens, topic, "subscribe",
                batch -> FirebaseMessaging.getInstance().subscribeToTopic(batch, topic));
    }

    public void unsubscribeTokensFromTopic(List<String> tokens, String topic) {
        runTopicOperation(tokens, topic, "unsubscribe",
                batch -> FirebaseMessaging.getInstance().unsubscribeFromTopic(batch, topic));
    }

    private void runTopicOperation(List<String> tokens, String topic, String action, TopicCall call) {
        if (tokens == null || tokens.isEmpty()) return;
        if (firebaseConfig.isMockMode()) {
            log.debug("[MOCK FCM] {} {} tokens, topic={}", action, tokens.size(), topic);
            return;
        }
        ensureFirebaseInitialized();

        for (int i = 0; i < tokens.size(); i += TOPIC_BATCH_SIZE) {
            List<String> batch = tokens.subList(i, Math.min(i + TOPIC_BATCH_SIZE, tokens.size()));
            try {
                TopicManagementResponse response = call.run(batch);
                if (response.getFailureCount() > 0) {
                    String reason = response.getErrors().get(0).getReason();
                    // Invalid/unknown token will never succeed, so don't retry it
                    boolean retryable = !"NOT_FOUND".equals(reason) && !"INVALID_ARGUMENT".equals(reason);
                    throw new FcmTopicSubscriptionException(
                            response.getFailureCount() + " of " + batch.size()
                                    + " tokens failed to " + action + " topic " + topic
                                    + " (reason=" + reason + ")",
                            null, retryable);
                }
            } catch (FirebaseMessagingException e) {
                throw new FcmTopicSubscriptionException(
                        "Failed to " + action + " topic " + topic, e, isRetryable(e));
            }
        }
    }

    private boolean isRetryable(FirebaseMessagingException e) {
        return FcmErrorClassifier.classify(e) == FcmErrorClassifier.ErrorCategory.TRANSIENT;
    }

    private void ensureFirebaseInitialized() {
        if (FirebaseApp.getApps().isEmpty()) {
            throw new FcmNotInitializedException();
        }
    }
}