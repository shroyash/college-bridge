package com.college.bridge.notification.dto;

import java.util.List;

public record DeviceDeactivationResult(String token, List<String> topics) {}