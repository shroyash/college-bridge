package com.college.bridge.holiday.infrastructure;

import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.tenant.TenantContext;
import com.college.bridge.holiday.application.port.Actor;
import com.college.bridge.holiday.application.port.CurrentUser;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component
public class SecurityCurrentUser implements CurrentUser {

    @Override
    public Actor actor() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.isAuthenticated() && auth.getPrincipal() instanceof UserPrincipal principal) {
            Long institutionId = principal.getInstitutionId();
            if (institutionId == null) {
                institutionId = TenantContext.get();
            }
            return new Actor(principal.getUserId(), institutionId);
        }

        Long tenantId = TenantContext.get();
        return new Actor(null, tenantId);
    }
}
