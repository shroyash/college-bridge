package com.college.bridge.academic.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(
    name = "academic_levels",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_academic_levels_program_number",
            columnNames = {"program_id", "level_number"}
        ),
        @UniqueConstraint(
            name = "uk_academic_levels_program_name",
            columnNames = {"program_id", "name"}
        )
    }
)
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AcademicLevel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "level_id")
    private Long levelId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "program_id", nullable = false)
    private AcademicProgram program;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    @Column(name = "level_number", nullable = false)
    private Integer levelNumber;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, length = 20)
    private AcademicLevelType type;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
