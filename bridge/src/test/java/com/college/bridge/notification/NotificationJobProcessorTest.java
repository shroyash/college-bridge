package com.college.bridge.notification;

import com.college.bridge.auth.entity.User;
import com.college.bridge.notification.dto.NotificationJobExecutionDto;
import com.college.bridge.notification.entity.*;
import com.college.bridge.notification.fcm.FcmNotificationService;
import com.college.bridge.notification.repository.FcmDeviceRepository;
import com.college.bridge.notification.repository.NotificationRecipientRepository;
import com.college.bridge.notification.service.NotificationJobProcessor;
import com.college.bridge.notification.service.NotificationJobStatusService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class NotificationJobProcessorTest {

    @Mock
    private NotificationRecipientRepository recipientRepository;

    @Mock
    private FcmDeviceRepository fcmDeviceRepository;

    @Mock
    private FcmNotificationService fcmService;

    @Mock
    private NotificationJobStatusService statusService;

    @InjectMocks
    private NotificationJobProcessor jobProcessor;

    @Test
    @DisplayName("Multi-device user with one delivered device is marked SENT and removed from failedIds")
    void testMultiDeviceUserMarkedSentIfAtLeastOneSucceeds() {
        Long notificationId = 100L;
        Long jobId = 1L;
        Long userId = 20L;
        Long recipientId = 555L;

        NotificationJobExecutionDto jobDto = NotificationJobExecutionDto.builder()
                .jobId(jobId)
                .notificationId(notificationId)
                .institutionId(1L)
                .title("Title")
                .body("Body")
                .targetType(NotificationTargetType.USERS)
                .type(NotificationType.DOUBT_POSTED)
                .attemptCount(0)
                .maxAttempts(5)
                .build();

        User user = User.builder().userId(userId).build();
        NotificationRecipient recipient = NotificationRecipient.builder()
                .recipientId(recipientId)
                .user(user)
                .deliveryStatus(RecipientDeliveryStatus.PENDING)
                .build();

        // 1. Pending recipient
        when(recipientRepository.findByNotificationIdAndDeliveryStatus(notificationId, RecipientDeliveryStatus.PENDING))
                .thenReturn(List.of(recipient));

        // 2. User has 2 active devices
        FcmDevice device1 = FcmDevice.builder().deviceId(10L).fcmToken("token-1").user(user).build();
        FcmDevice device2 = FcmDevice.builder().deviceId(11L).fcmToken("token-2").user(user).build();
        when(fcmDeviceRepository.findActiveDevicesByUserIds(List.of(userId), 1L))
                .thenReturn(List.of(device1, device2));

        // 3. FCM sends to token-1 (succeeds) and token-2 (fails)
        FcmNotificationService.FcmMulticastBatchResult batchResult = new FcmNotificationService.FcmMulticastBatchResult(
                List.of(0), // token-1 succeeded
                List.of("token-2"), // token-2 permanent failure
                List.of(),
                List.of(1)
        );
        when(fcmService.sendToTokens(anyList(), anyString(), anyString(), anyMap()))
                .thenReturn(batchResult);

        jobProcessor.processJob(jobDto);

        ArgumentCaptor<List<Long>> deliveredCaptor = ArgumentCaptor.forClass(List.class);
        ArgumentCaptor<List<Long>> failedCaptor = ArgumentCaptor.forClass(List.class);

        verify(statusService).updateRecipientBatch(deliveredCaptor.capture(), failedCaptor.capture(), anyList());

        // deliveredIds contains recipientId 555L
        assertTrue(deliveredCaptor.getValue().contains(recipientId));
        // failedIds MUST NOT contain recipientId 555L because token-1 succeeded
        assertFalse(failedCaptor.getValue().contains(recipientId));
        assertTrue(failedCaptor.getValue().isEmpty());

        verify(statusService).markJobSent(jobId, 0);
    }
}
