package com.college.bridge.clazz.entity;

import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.institution.entity.Institution;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;

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

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "institution_id", nullable = false)
    private Institution institution;

    @Column(name = "class_name", nullable = false, length = 100)
    private String className;

    @Column(name = "subject", length = 100)
    private String subject;

    @Column(name = "semester")
    private Integer semester;

    @Column(name = "faculty", length = 20)
    private String faculty;

    @Column(name = "department", length = 100)
    private String department;

    @Column(name = "fcm_topic_id", nullable = false, unique = true, length = 150)
    private String fcmTopicId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "teacher_id")
    private Teacher teacher;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
