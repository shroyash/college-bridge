package com.college.bridge.academic.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * Represents a cohort (class group) defined by a unique Faculty + Semester pair.
 * <p>
 * Example: Faculty=BCA, Semester=1 → displayName="BCA First Semester"
 * <p>
 * When a student registers and selects their faculty and semester, the backend
 * looks up the matching {@code AcademicClass} and enrolls the student.
 */
@Entity
@Table(
    name = "academic_classes",
    uniqueConstraints = @UniqueConstraint(columnNames = {"faculty", "semester"})
)
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AcademicClass {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "class_id")
    private Long classId;

    @Enumerated(EnumType.STRING)
    @Column(name = "faculty", nullable = false, length = 20)
    private Faculty faculty;

    @Column(name = "semester", nullable = false)
    private Integer semester;

    /**
     * Human-readable name, e.g. "BCA First Semester", "BSC CSIT Third Semester".
     * Auto-generated during seeding.
     */
    @Column(name = "display_name", nullable = false, length = 100)
    private String displayName;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
