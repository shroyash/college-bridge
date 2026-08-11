package com.college.bridge.auth.security;

import com.college.bridge.auth.entity.User;

/**
 * CustomUserDetails extending UserPrincipal for backward compatibility.
 */
public class CustomUserDetails extends UserPrincipal {

    public CustomUserDetails(User user, Long studentId, Long teacherId) {
        super(user, studentId, teacherId);
    }

    public CustomUserDetails(User user) {
        super(user, null, null);
    }
}