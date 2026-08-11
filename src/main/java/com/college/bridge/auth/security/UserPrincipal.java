package com.college.bridge.auth.security;

import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.entity.UserStatus;
import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.Collections;

@Getter
public class UserPrincipal implements UserDetails {

    private final User user;
    private final Long userId;
    private final Long institutionId;
    private final UserRole role;
    private final Long studentId;
    private final Long teacherId;

    public UserPrincipal(User user, Long studentId, Long teacherId) {
        this.user = user;
        this.userId = user.getUserId();
        this.institutionId = user.getInstitution() != null ? user.getInstitution().getInstitutionId() : null;
        this.role = user.getRole();
        this.studentId = studentId;
        this.teacherId = teacherId;
    }

    public UserPrincipal(User user) {
        this(user, null, null);
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return Collections.singletonList(new SimpleGrantedAuthority("ROLE_" + role.name()));
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
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return user != null
                && UserStatus.ACTIVE.equals(user.getStatus())
                && !user.isDeleted();
    }
}
