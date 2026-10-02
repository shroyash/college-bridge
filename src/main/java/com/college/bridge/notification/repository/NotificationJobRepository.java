package com.college.bridge.notification.repository;

import com.college.bridge.notification.entity.JobStatus;
import com.college.bridge.notification.entity.NotificationJob;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
public interface NotificationJobRepository extends JpaRepository<NotificationJob, Long> {

    @Query(value = """
        SELECT j.job_id FROM notification_jobs j
        WHERE j.attempt_count < j.max_attempts
          AND (
            (j.status IN ('PENDING', 'RETRYING') AND j.next_attempt_at <= :now)
            OR (j.status = 'PROCESSING' AND j.lease_expires_at < :now)
          )
        ORDER BY j.job_id ASC
        LIMIT :limit
        FOR UPDATE SKIP LOCKED
    """, nativeQuery = true)
    List<Long> findClaimableJobIds(@Param("now") Instant now, @Param("limit") int limit);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
        UPDATE NotificationJob j
        SET j.status = :status,
            j.lockedAt = :now,
            j.leaseExpiresAt = :leaseExpiresAt,
            j.attemptCount = j.attemptCount + 1,
            j.updatedAt = :now
        WHERE j.jobId IN :jobIds
    """)
    int markJobsProcessing(
            @Param("jobIds") List<Long> jobIds,
            @Param("status") JobStatus status,
            @Param("now") Instant now,
            @Param("leaseExpiresAt") Instant leaseExpiresAt
    );

    @Query("""
        SELECT j FROM NotificationJob j
        JOIN FETCH j.notification n
        LEFT JOIN FETCH n.institution i
        WHERE j.jobId = :jobId
    """)
    Optional<NotificationJob> findByIdWithNotification(@Param("jobId") Long jobId);
}
