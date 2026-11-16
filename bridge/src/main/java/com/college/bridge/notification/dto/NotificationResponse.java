package com.college.bridge.notification.dto;

import com.college.bridge.notification.entity.NotificationTargetType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationResponse {
    private Long notificationId;
    private Long institutionId;
    private Long senderId;
    private String senderName;
    private String title;
    private String body;
    private NotificationTargetType targetType;
    private Long targetId;
    private String status;
    private String idempotencyKey;
    private Instant createdAt;
}
