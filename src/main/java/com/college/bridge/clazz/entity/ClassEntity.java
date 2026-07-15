package com.college.bridge.clazz.entity;

import com.college.bridge.academic.entity.Faculty;
import com.college.bridge.auth.entity.Teacher;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;

/**
 * Represents a teaching class — a specific subject being taught to a
 * specific faculty cohort in a specific semester.
 * <p>
 * A teacher may be assigned or unassigned; unassigned classes have {@code teacher == null}.
 * Admin assigns the teacher after class creation.
 */
@Entity
@Table(name = "classes")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClassEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "class_id")
    private Long classId;

    @Column(name = "class_name", nullable = false, length = 100)
    private String className;

    @Column(name = "subject", length = 100)
    private String subject;

    @Column(name = "semester")
    private Integer semester;

    /**
     * The faculty this class belongs to, allowing admins to filter
     * classes by programme.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "faculty", length = 20)
    private Faculty faculty;

    @Column(name = "department", length = 100)
    private String department;

    /** FCM topic ID used for push notifications to all class subscribers. */
    @Column(name = "fcm_topic_id", nullable = false, unique = true, length = 150)
    private String fcmTopicId;

    /** Nullable until admin assigns a teacher. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "teacher_id")
    private Teacher teacher;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}

