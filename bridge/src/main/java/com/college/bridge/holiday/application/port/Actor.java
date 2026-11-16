package com.college.bridge.holiday.application.port;

import com.college.bridge.holiday.domain.NoticeForbiddenException;

/**
 * The authenticated caller. The institution comes ONLY from the verified login (never from the request body),
 * and is null for platform users such as the super admin.
 */
public record Actor(Long userId, Long institutionId) {

    public Long requireInstitutionId() {
        if (institutionId == null) {
            throw new NoticeForbiddenException("This action requires an institution account");
        }
        return institutionId;
    }
}
