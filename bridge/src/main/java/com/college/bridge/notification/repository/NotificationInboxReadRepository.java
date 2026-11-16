package com.college.bridge.notification.repository;

import com.college.bridge.notification.entity.NotificationInboxRead;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collection;
import java.util.Collections;
import java.util.Set;

@Repository
public interface NotificationInboxReadRepository extends JpaRepository<NotificationInboxRead, Long> {

    @Query("""
        SELECT r.notification.notificationId
        FROM NotificationInboxRead r
        WHERE r.user.userId = :userId
          AND r.notification.notificationId IN :ids
    """)
    Set<Long> queryReadNotificationIds(@Param("userId") Long userId, @Param("ids") Collection<Long> ids);

    default Set<Long> findReadNotificationIds(Long userId, Collection<Long> ids) {
        if (ids == null || ids.isEmpty()) {
            return Collections.emptySet();
        }
        return queryReadNotificationIds(userId, ids);
    }

    @Modifying(flushAutomatically = true)
    @Transactional
    @Query(value = """
        INSERT IGNORE INTO notification_inbox_reads (notification_id, user_id, read_at)
        VALUES (:notificationId, :userId, NOW(6))
    """, nativeQuery = true)
    int markReadNative(@Param("notificationId") Long notificationId, @Param("userId") Long userId);

    boolean existsByNotification_NotificationIdAndUser_UserId(Long notificationId, Long userId);
}
