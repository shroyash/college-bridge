package com.college.bridge.holiday.controller.dto;

import com.college.bridge.holiday.domain.NoticeAudience;
import com.college.bridge.holiday.domain.NoticeDraft;
import com.college.bridge.holiday.domain.NoticeVariant;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.EnumSet;
import java.util.Set;

/**
 * Approve one shared draft, optionally with this institution's own wording.
 * {@code audience} is an enum whitelist (STUDENTS, TEACHERS); an empty value defaults to students.
 * Supports legacy boolean flags notifyStudents and notifyTeachers as fallbacks.
 * There is deliberately NO institution id here: it comes from the login.
 */
public record NoticeApprovalRequest(
        @NotNull NoticeVariant variant,
        @Size(max = NoticeDraft.TITLE_MAX_LENGTH) String customTitle,
        @Size(max = NoticeDraft.BODY_MAX_LENGTH) String customBody,
        Set<NoticeAudience> audience,
        Boolean notifyStudents,
        Boolean notifyTeachers) {

    public NoticeApprovalRequest {
        if (audience == null || audience.isEmpty()) {
            Set<NoticeAudience> resolved = EnumSet.noneOf(NoticeAudience.class);
            if (Boolean.TRUE.equals(notifyStudents)) {
                resolved.add(NoticeAudience.STUDENTS);
            }
            if (Boolean.TRUE.equals(notifyTeachers)) {
                resolved.add(NoticeAudience.TEACHERS);
            }
            audience = resolved.isEmpty() ? EnumSet.of(NoticeAudience.STUDENTS) : resolved;
        } else {
            audience = EnumSet.copyOf(audience);
        }
    }

    public NoticeApprovalRequest(NoticeVariant variant, String customTitle, String customBody, Set<NoticeAudience> audience) {
        this(variant, customTitle, customBody, audience, null, null);
    }
}
