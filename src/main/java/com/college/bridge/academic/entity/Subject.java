package com.college.bridge.academic.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(
    name = "subjects",
    uniqueConstraints = @UniqueConstraint(
        name = "uk_subjects_level_name",
        columnNames = {"level_id", "name"}
    )
)
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Subject {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "subject_id")
    private Long subjectId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "level_id", nullable = false)
    private AcademicLevel academicLevel;

    @Column(name = "name", nullable = false, length = 150)
    private String name;

    @Column(name = "code", length = 50)
    private String code;

    @Column(name = "credit_hours")
    private Integer creditHours;

    @Column(name = "fcm_topic_id", length = 100)
    private String fcmTopicId;

    @OneToMany(mappedBy = "subject")
    @Builder.Default
    private Set<TeacherAssignment> assignments = new HashSet<>();

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}