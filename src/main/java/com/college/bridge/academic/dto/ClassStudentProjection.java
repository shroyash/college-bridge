package com.college.bridge.academic.dto;

import com.college.bridge.auth.entity.UserStatus;

public interface ClassStudentProjection {

    Long getStudentId();

    Long getUserId();

    String getFullName();

    String getEmail();

    UserStatus getStatus();
}