package com.college.bridge.notification.entity;

import com.college.bridge.academic.entity.AcademicClass;
import com.college.bridge.academic.entity.Subject;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "notification_targets")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationTarget {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "target_id")
    private Long targetId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "notification_id", nullable = false)
    private Notification notification;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "academic_class_id")
    private AcademicClass academicClass;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "subject_id")
    private Subject subject;

    @Enumerated(EnumType.STRING)
    @Column(name = "target_type", length = 20)
    private TargetType targetType;
}
