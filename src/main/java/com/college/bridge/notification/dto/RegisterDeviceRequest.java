package com.college.bridge.notification.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RegisterDeviceRequest {

    @NotBlank(message = "FCM token is required")
    @Size(max = 500, message = "Token cannot exceed 500 characters")
    private String token;

    @NotBlank(message = "Platform is required (e.g. ANDROID, IOS, WEB)")
    @Size(max = 20, message = "Platform cannot exceed 20 characters")
    private String platform;
}
