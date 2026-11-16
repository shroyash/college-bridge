package com.college.bridge.notification.dto;

import com.college.bridge.notification.entity.NotificationTargetType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateNotificationRequest {

    @NotBlank(message = "Title is required")
    @Size(max = 200, message = "Title must not exceed 200 characters")
    private String title;

    @NotBlank(message = "Body is required")
    @Size(max = 4000, message = "Body must not exceed 4000 characters")
    private String body;

    @NotNull(message = "Target type is required")
    private NotificationTargetType targetType;

    // Required for CLASS (levelId) or SUBJECT (subjectId)
    private Long targetId;

    private List<Long> userIds;

    @Size(max = 255, message = "Idempotency key must not exceed 255 characters")
    private String idempotencyKey;

}
