package com.college.bridge.academic.entity;

import com.college.bridge.institution.entity.Institution;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(
    name = "academic_classes",
    uniqueConstraints = @UniqueConstraint(
        name = "uk_academic_classes_institution_faculty_semester",
        columnNames = {"institution_id", "faculty", "semester"}
    )
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

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "institution_id", nullable = false)
    private Institution institution;

    @Column(name = "faculty", nullable = false, length = 20)
    private String faculty;

    @Column(name = "semester", nullable = false)
    private Integer semester;

    @Column(name = "display_name", nullable = false, length = 100)
    private String displayName;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
