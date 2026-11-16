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
public class NotificationInboxResponse {
    private Long notificationId;
    private String title;
    private String body;
    private Long senderId;
    private String senderName;
    private NotificationTargetType targetType;
    private Long targetId;
    private Instant createdAt;
    private boolean read;
}

