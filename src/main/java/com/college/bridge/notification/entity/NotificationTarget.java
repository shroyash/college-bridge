package com.college.bridge.notification.entity;

import com.college.bridge.academic.entity.AcademicLevel;
import com.college.bridge.academic.entity.Subject;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "notification_targets")
@Getter
@Setter
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
    @JoinColumn(name = "level_id")
    private AcademicLevel academicLevel;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "subject_id")
    private Subject subject;

    @Enumerated(EnumType.STRING)
    @Column(name = "target_type", length = 20)
    private TargetType targetType;
}
