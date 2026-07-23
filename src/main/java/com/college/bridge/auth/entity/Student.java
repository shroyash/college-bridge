package com.college.bridge.auth.entity;

import com.college.bridge.academic.entity.AcademicClass;
import jakarta.persistence.*;
import lombok.*;

/**
 * Student profile linked to a {@link User}.
 * <p>
 * The {@code academicClass} FK automatically encodes the student's
 * faculty and semester — no need for raw department/semester fields.
 */
@Entity
@Table(name = "students")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Student {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "student_id")
    private Long studentId;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /**
     * The academic class (faculty + semester cohort) this student belongs to.
     * Resolved automatically on registration from the faculty + semester the
     * student selects.
     */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "academic_class_id", nullable = false)
    private AcademicClass academicClass;

    @org.hibernate.annotations.CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private java.time.LocalDateTime createdAt = java.time.LocalDateTime.now();

    @org.hibernate.annotations.UpdateTimestamp
    @Column(name = "updated_at")
    private java.time.LocalDateTime updatedAt;

    @Version
    @Column(name = "version")
    private Long version;
}
