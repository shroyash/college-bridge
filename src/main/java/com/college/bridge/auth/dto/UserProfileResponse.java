package com.college.bridge.auth.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserProfileResponse {
    private Long userId;
    private String name;
    private String email;
    private String role;
    private String status;
    private String imageUrl;
    private String fcmToken;
    private StudentProfileDetails studentDetails;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class StudentProfileDetails {
        private String faculty;
        private String semester;
        private Long academicClassId;
    }
}
