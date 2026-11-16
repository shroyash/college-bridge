package com.college.bridge.holiday.domain;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

/**
 * One AI-written draft (CLOSED or OPEN) for a holiday. SHARED by all institutions: it has no institution id
 * and is never edited by a college (colleges customise their own copy at approval time).
 */
@Entity
@Table(name = "holiday_notice_drafts",
        uniqueConstraints = @UniqueConstraint(name = "uq_notice_drafts_holiday_variant", columnNames = {"holiday_id", "variant"}))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class NoticeDraft {

    /** Single source of truth for text limits (database columns, validation, AI output checks). */
    public static final int TITLE_MAX_LENGTH = 255;
    public static final int BODY_MAX_LENGTH = 2000;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "holiday_id", nullable = false)
    private Long holidayId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private NoticeVariant variant;

    @Column(nullable = false, length = TITLE_MAX_LENGTH)
    private String title;

    @Column(nullable = false, length = BODY_MAX_LENGTH)
    private String body;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private DraftOrigin origin;

    @Column(length = 64)
    private String model;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public static NoticeDraft create(Long holidayId, NoticeVariant variant, String title, String body,
                                     DraftOrigin origin, String model) {
        NoticeDraft draft = new NoticeDraft();
        draft.holidayId = holidayId;
        draft.variant = variant;
        draft.replaceWith(title, body, origin, model);
        return draft;
    }

    /** New written text replaces the old one (regeneration, or upgrading a template to AI text). */
    public void replaceWith(String newTitle, String newBody, DraftOrigin newOrigin, String newModel) {
        this.title = newTitle;
        this.body = newBody;
        this.origin = newOrigin;
        this.model = newModel;
    }

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
