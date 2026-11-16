package com.college.bridge.notification.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

@Entity
@Table(
    name = "device_topic_subscriptions",
    uniqueConstraints = @UniqueConstraint(name = "uk_device_topic", columnNames = {"device_id", "topic"})
)
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeviceTopicSubscription {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "subscription_id")
    private Long subscriptionId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "device_id", nullable = false)
    private FcmDevice device;

    @Column(name = "topic", nullable = false, length = 150)
    private String topic;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private Instant createdAt = Instant.now();
}
