package com.college.bridge.auth.security;

import com.college.bridge.auth.entity.User;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import java.util.Collection;
import java.util.Collections;

public class CustomUserDetails implements UserDetails {

    private final User user;
    private final Long studentId;
    private final Long teacherId;


    public CustomUserDetails(User user, Long studentId, Long teacherId) {
        this.user = user;
        this.studentId = studentId;
        this.teacherId = teacherId;
    }

    public CustomUserDetails(User user) {
        this(user, null, null);
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return Collections.singletonList(new SimpleGrantedAuthority("ROLE_" + user.getRole().name()));
    }

    @Override
    public String getPassword() {
        return user.getPasswordHash();
    }

    @Override
    public String getUsername() {
        return user.getEmail();
    }

    @Override
    public boolean isAccountNonExpired() { return true; }

    @Override
    public boolean isAccountNonLocked() { return true; }

    @Override
    public boolean isCredentialsNonExpired() { return true; }

    @Override
    public boolean isEnabled() {
        return user != null
                && com.college.bridge.auth.entity.UserStatus.ACTIVE.equals(user.getStatus())
                && !user.isDeleted();
    }

    public User getUser() {
        return this.user;
    }

    public Long getStudentId() {
        return studentId;
    }

    public Long getTeacherId() {
        return teacherId;
    }
}