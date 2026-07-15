package com.college.bridge.academic.entity;

import com.college.bridge.auth.entity.Student;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * Records a student's enrollment in a specific subject.
 * <p>
 * Created automatically by the backend when a student registers —
 * one record per subject in the chosen faculty+semester combination.
 */
@Entity
@Table(
    name = "subject_enrollments",
    uniqueConstraints = @UniqueConstraint(columnNames = {"student_id", "subject_id"})
)
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SubjectEnrollment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "enrollment_id")
    private Long enrollmentId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "subject_id", nullable = false)
    private Subject subject;

    @CreationTimestamp
    @Column(name = "enrolled_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime enrolledAt = LocalDateTime.now();
}
