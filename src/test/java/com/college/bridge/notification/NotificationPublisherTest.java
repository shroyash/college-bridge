package com.college.bridge.notification;

import com.college.bridge.notification.dto.NotificationPublishRequest;
import com.college.bridge.notification.entity.Notification;
import com.college.bridge.notification.repository.NotificationRepository;
import com.college.bridge.notification.service.NotificationInternalTxWriter;
import com.college.bridge.notification.service.NotificationPublisher;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class NotificationPublisherTest {

    @Mock
    private NotificationInternalTxWriter txWriter;

    @Mock
    private NotificationRepository notificationRepository;

    @InjectMocks
    private NotificationPublisher notificationPublisher;

    @Test
    @DisplayName("Duplicate event with unique constraint collision catches exception and returns existing notification")
    void testDuplicateEventReturnsExistingNotification() {
        String key = "DOUBT_POSTED:123";
        NotificationPublishRequest request = NotificationPublishRequest.builder()
                .idempotencyKey(key)
                .build();

        Notification existingNotification = Notification.builder()
                .notificationId(999L)
                .idempotencyKey(key)
                .title("Existing Notice")
                .build();

        when(txWriter.createNotificationTransactional(request))
                .thenThrow(new DataIntegrityViolationException("Duplicate entry for key 'uk_notifications_idempotency'"));

        when(notificationRepository.findByIdempotencyKey(key))
                .thenReturn(Optional.of(existingNotification));

        Notification result = notificationPublisher.publish(request);

        assertNotNull(result);
        assertEquals(999L, result.getNotificationId());
        assertEquals("Existing Notice", result.getTitle());
    }

    @Test
    @DisplayName("Normal insert returns newly created notification")
    void testNormalInsertReturnsCreatedNotification() {
        String key = "DOUBT_POSTED:124";
        NotificationPublishRequest request = NotificationPublishRequest.builder()
                .idempotencyKey(key)
                .build();

        Notification newNotification = Notification.builder()
                .notificationId(1000L)
                .idempotencyKey(key)
                .title("New Notice")
                .build();

        when(txWriter.createNotificationTransactional(request))
                .thenReturn(newNotification);

        Notification result = notificationPublisher.publish(request);

        assertNotNull(result);
        assertEquals(1000L, result.getNotificationId());
        verify(notificationRepository, never()).findByIdempotencyKey(any());
    }
}
