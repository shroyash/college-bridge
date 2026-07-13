package com.college.bridge.notification.entity;

import com.college.bridge.clazz.entity.ClassEntity;
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
    @JoinColumn(name = "class_id")
    private ClassEntity classEntity;

    @Enumerated(EnumType.STRING)
    @Column(name = "target_type", length = 20)
    private TargetType targetType;
}
