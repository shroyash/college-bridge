package com.college.bridge.doubt.entity;

import com.college.bridge.academic.entity.Subject;
import com.college.bridge.auth.entity.Student;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "doubts")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Doubt {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "doubt_id")
    private Long doubtId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "subject_id", nullable = false)
    private Subject subject;

    @Column(name = "question", nullable = false, columnDefinition = "TEXT")
    private String question;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private DoubtStatus status = DoubtStatus.OPEN;

    @Column(name = "is_helpful", nullable = false)
    @Builder.Default
    private Boolean isHelpful = false;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}