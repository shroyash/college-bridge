package com.college.bridge.auth.dto;


import com.college.bridge.auth.entity.UserStatus;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class TeacherResponse {

    private Long teacherId;

    private Long userId;

    private String name;

    private String email;

    private UserStatus status;

    private LocalDateTime createdAt;
}