package com.college.bridge.notification.dto;

import java.util.List;

public record DeviceRegistrationResult(Long deviceId, String token,
                                       boolean reassigned, List<String> oldTopics) {}