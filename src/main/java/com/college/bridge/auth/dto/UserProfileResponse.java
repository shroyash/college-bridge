package com.college.bridge.auth.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserProfileResponse {
    private Long userId;
    private Long teacherId;
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
        private Long studentId;
        private String faculty;
        private Integer semester;
        private Long academicClassId;
        private String displayName;
    }
}
