package com.college.bridge.auth.dto;

import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.entity.UserStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SuperAdminUserResponse {

    private Long id;
    private String name;
    private String email;
    private String profileImage;
    private UserRole role;
    private UserStatus status;
    private Long institutionId;
    private String institutionName;
    private LocalDateTime createdAt;
}
