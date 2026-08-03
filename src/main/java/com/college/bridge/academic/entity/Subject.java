package com.college.bridge.academic.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.HashSet;
import java.util.Set;


@Entity
@Table(
        name = "subjects",
        uniqueConstraints = @UniqueConstraint(
                columnNames = {"faculty", "semester", "name"}
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

    @Column(name = "name", nullable = false, length = 150)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(name = "faculty", nullable = false, length = 20)
    private Faculty faculty;

    @Column(name = "semester", nullable = false)
    private Integer semester;

    @Column(name = "credit_hours")
    private Integer creditHours;

    @OneToMany(mappedBy = "subject")
    @Builder.Default
    private Set<TeacherAssignment> assignments = new HashSet<>();
}