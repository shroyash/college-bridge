package com.college.bridge.notification.repository;

import com.college.bridge.notification.entity.FcmDevice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
public interface FcmDeviceRepository extends JpaRepository<FcmDevice, Long> {

    Optional<FcmDevice> findByFcmToken(String fcmToken);

    List<FcmDevice> findByUser_UserIdAndActiveTrue(Long userId);

    @Query("""
        SELECT d FROM FcmDevice d
        JOIN FETCH d.user u
        WHERE u.userId IN :userIds
          AND (d.institution.institutionId = :institutionId OR :institutionId IS NULL)
          AND d.active = true
    """)
    List<FcmDevice> findActiveDevicesByUserIds(
            @Param("userIds") List<Long> userIds,
            @Param("institutionId") Long institutionId
    );

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
        UPDATE FcmDevice d
        SET d.active = false, d.updatedAt = :now
        WHERE d.fcmToken IN :tokens
    """)
    int deactivateTokens(@Param("tokens") List<String> tokens, @Param("now") Instant now);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
        UPDATE FcmDevice d
        SET d.active = false, d.updatedAt = :now
        WHERE d.fcmToken = :token AND d.user.userId = :userId
    """)
    int deactivateUserToken(
            @Param("token") String token,
            @Param("userId") Long userId,
            @Param("now") Instant now
    );
}
