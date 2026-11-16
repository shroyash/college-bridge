package com.college.bridge.auth.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OtpVerificationResponse {
    private boolean verified;
    private String verificationToken;
}
