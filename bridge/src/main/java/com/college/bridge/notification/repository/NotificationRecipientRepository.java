package com.college.bridge.notification.repository;

import com.college.bridge.notification.entity.NotificationRecipient;
import com.college.bridge.notification.entity.RecipientDeliveryStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface NotificationRecipientRepository extends JpaRepository<NotificationRecipient, Long> {

    @Query("""
        SELECT nr FROM NotificationRecipient nr
        JOIN FETCH nr.user u
        WHERE nr.notification.notificationId = :notificationId
          AND nr.deliveryStatus = :status
    """)
    List<NotificationRecipient> findByNotificationIdAndDeliveryStatus(
            @Param("notificationId") Long notificationId,
            @Param("status") RecipientDeliveryStatus status
    );

    @Query("""
        SELECT nr.user.userId FROM NotificationRecipient nr
        WHERE nr.notification.notificationId = :notificationId
    """)
    List<Long> findUserIdsByNotificationId(@Param("notificationId") Long notificationId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
        UPDATE NotificationRecipient nr
        SET nr.deliveryStatus = :status,
            nr.deliveredAt = :now
        WHERE nr.recipientId IN :recipientIds
    """)
    int updateStatusForIds(
            @Param("recipientIds") List<Long> recipientIds,
            @Param("status") RecipientDeliveryStatus status,
            @Param("now") Instant now
    );
}
