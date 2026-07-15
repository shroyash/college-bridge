package com.college.bridge.academic.entity;

import jakarta.persistence.*;
import lombok.*;

/**
 * Represents a subject taught in a specific faculty and semester.
 * <p>
 * Example: BCA Semester 1 — "Mathematics", "Digital Logic", etc.
 * Subjects are seeded by {@code AcademicDataInitializer} and are not user-managed.
 */
@Entity
@Table(
    name = "subjects",
    uniqueConstraints = @UniqueConstraint(columnNames = {"faculty", "semester", "name"})
)
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Subject {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "subject_id")
    private Long subjectId;

    @Column(name = "name", nullable = false, length = 150)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(name = "faculty", nullable = false, length = 20)
    private Faculty faculty;

    @Column(name = "semester", nullable = false)
    private Integer semester;

    @Column(name = "credit_hours")
    private Integer creditHours;
}
