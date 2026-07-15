package com.college.bridge.auth.entity;

import jakarta.persistence.*;
import lombok.*;

/**
 * Teacher profile linked to a {@link User}.
 * <p>
 * Teachers do NOT belong to a single department or subject.
 * They are assigned to individual classes by the admin after
 * their Teacher Verification Request is approved.
 */
@Entity
@Table(name = "teachers")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Teacher {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "teacher_id")
    private Long teacherId;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
}
