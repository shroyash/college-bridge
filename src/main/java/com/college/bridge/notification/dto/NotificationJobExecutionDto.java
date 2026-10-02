package com.college.bridge.notification.dto;

import com.college.bridge.notification.entity.NotificationTargetType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationJobExecutionDto {
    private Long jobId;
    private Long notificationId;
    private Long institutionId;
    private String title;
    private String body;
    private NotificationTargetType targetType;
    private Long targetId;
    private int attemptCount;
    private int maxAttempts;
}
