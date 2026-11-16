package com.college.bridge.holiday.domain;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

/** Audit trail: who did what. {@code institutionId} is null for platform-level actions (super admin). */
@Entity
@Table(name = "holiday_notice_actions",
        indexes = @Index(name = "idx_notice_actions_holiday", columnList = "holiday_id"))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class AdminAction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "holiday_id", nullable = false)
    private Long holidayId;

    @Column(name = "institution_id")
    private Long institutionId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 24)
    private AdminActionType type;

    @Column(name = "acted_at", nullable = false)
    private Instant actedAt = Instant.now();

    public static AdminAction of(Long holidayId, Long institutionId, Long userId, AdminActionType type) {
        AdminAction action = new AdminAction();
        action.holidayId = holidayId;
        action.institutionId = institutionId;
        action.userId = userId;
        action.type = type;
        return action;
    }
}
