package com.college.bridge.notification.repository;

import com.college.bridge.notification.entity.Notification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {

    Optional<Notification> findByIdempotencyKey(String idempotencyKey);

    Optional<Notification> findByNotificationIdAndInstitution_InstitutionId(Long notificationId, Long institutionId);

    @Query("""
        SELECT n FROM Notification n
        WHERE n.institution.institutionId = :institutionId
          AND (
               n.targetType = com.college.bridge.notification.entity.NotificationTargetType.INSTITUTION
            OR (n.targetType = com.college.bridge.notification.entity.NotificationTargetType.CLASS AND n.targetId = :levelId)
            OR (n.targetType = com.college.bridge.notification.entity.NotificationTargetType.SUBJECT AND n.targetId IN :subjectIds)
            OR (n.targetType = com.college.bridge.notification.entity.NotificationTargetType.USERS AND EXISTS (
                   SELECT nr FROM NotificationRecipient nr
                   WHERE nr.notification = n AND nr.user.userId = :userId
               ))
          )
        ORDER BY n.createdAt DESC
    """)
    Page<Notification> findUserInbox(
            @Param("institutionId") Long institutionId,
            @Param("userId") Long userId,
            @Param("levelId") Long levelId,
            @Param("subjectIds") List<Long> subjectIds,
            Pageable pageable
    );
}
