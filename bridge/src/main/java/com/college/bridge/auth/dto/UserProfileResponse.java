package com.college.bridge.auth.dto;

import com.college.bridge.academic.entity.AcademicLevelType;
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
        private Long levelId;
        private String levelName;
        private Integer levelNumber;
        private AcademicLevelType levelType;
        private Long programId;
        private String programName;
        private String programCode;
    }
}
