package com.college.bridge.holiday.domain;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

/**
 * ONE institution's decision about ONE holiday. This row is both the approval record and, once approved,
 * the official announcement (its final text is a snapshot, so later draft changes never alter it).
 * It also acts as the notification outbox: delivery state (attempts, next attempt, error) lives here,
 * one row per institution (not per student).
 *
 * State changes happen through atomic conditional updates in {@link InstitutionNoticeRepository},
 * so two admins of the same college, or two servers, can never approve or publish twice.
 */
@Entity
@Table(name = "institution_holiday_notices",
        uniqueConstraints = @UniqueConstraint(name = "uq_inst_notice_holiday_institution",
                columnNames = {"holiday_id", "institution_id"}),
        indexes = {
                @Index(name = "idx_inst_notice_status_next", columnList = "status,next_attempt_at"),
                @Index(name = "idx_inst_notice_institution_status", columnList = "institution_id,status")
        })
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class InstitutionNotice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "holiday_id", nullable = false)
    private Long holidayId;

    @Column(name = "institution_id", nullable = false)
    private Long institutionId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 24)
    private NoticeStatus status = NoticeStatus.AWAITING_DECISION;

    @Enumerated(EnumType.STRING)
    @Column(name = "approved_variant", length = 16)
    private NoticeVariant approvedVariant;

    @Column(name = "final_title", length = NoticeDraft.TITLE_MAX_LENGTH)
    private String finalTitle;

    @Column(name = "final_body", length = NoticeDraft.BODY_MAX_LENGTH)
    private String finalBody;

    @Column(name = "notify_students", nullable = false)
    private boolean notifyStudents;

    @Column(name = "notify_teachers", nullable = false)
    private boolean notifyTeachers;

    /** Admin who approved or rejected. */
    @Column(name = "decided_by")
    private Long decidedBy;

    @Column(name = "decided_at")
    private Instant decidedAt;

    @Column(name = "publish_attempts", nullable = false)
    private int publishAttempts;

    /** The publisher only picks rows whose next attempt time has arrived (backoff). */
    @Column(name = "next_attempt_at")
    private Instant nextAttemptAt;

    @Column(name = "published_at")
    private Instant publishedAt;

    @Column(name = "last_error", length = 500)
    private String lastError;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public static InstitutionNotice awaitingDecision(Long holidayId, Long institutionId) {
        InstitutionNotice notice = new InstitutionNotice();
        notice.holidayId = holidayId;
        notice.institutionId = institutionId;
        return notice;
    }

    public boolean isAwaitingDecision() {
        return status == NoticeStatus.AWAITING_DECISION;
    }

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
