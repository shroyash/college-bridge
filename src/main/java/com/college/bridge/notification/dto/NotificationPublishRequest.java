package com.college.bridge.notification.dto;

import com.college.bridge.notification.entity.NotificationTargetType;
import com.college.bridge.notification.entity.NotificationType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationPublishRequest {
    private Long institutionId;
    private String title;
    private String body;
    private NotificationTargetType targetType;
    private Long targetId;
    private List<Long> userIds;
    private NotificationType type;
    private Long senderUserId;
    private String idempotencyKey;
}

