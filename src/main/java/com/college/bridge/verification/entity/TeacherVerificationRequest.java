package com.college.bridge.verification.entity;

import com.college.bridge.auth.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Represents a user's request to be verified and promoted to {@code ROLE_TEACHER}.
 * <p>
 * Workflow:
 * <pre>
 *   Student submits request  →  PENDING
 *   Admin reviews            →  APPROVED or REJECTED
 *   On approval              →  User role upgraded to ROLE_TEACHER
 * </pre>
 */
@Entity
@Table(name = "teacher_verification_requests")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TeacherVerificationRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "request_id")
    private Long requestId;

    /** The user requesting teacher status. */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private VerificationStatus status = VerificationStatus.PENDING;

    /**
     * List of document URLs provided by the applicant
     * (e.g. teaching licence, employment proof, certificates).
     * Stored as a comma-separated string internally.
     */
    @ElementCollection
    @CollectionTable(name = "verification_documents", joinColumns = @JoinColumn(name = "request_id"))
    @Column(name = "document_url", length = 500)
    private List<String> documentUrls;

    /** Only populated when status is REJECTED. */
    @Column(name = "rejection_reason", columnDefinition = "TEXT")
    private String rejectionReason;

    /** The admin user who reviewed this request. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reviewed_by")
    private User reviewedBy;

    @Column(name = "reviewed_at")
    private LocalDateTime reviewedAt;

    @CreationTimestamp
    @Column(name = "submitted_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime submittedAt = LocalDateTime.now();

    @org.hibernate.annotations.UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Version
    @Column(name = "version")
    private Long version;
}
