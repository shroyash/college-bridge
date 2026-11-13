package com.college.bridge.holiday.domain;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

/**
 * Every state change is ONE conditional UPDATE ("... where status = <expected>") that returns how many rows
 * changed: 1 means this caller won, 0 means someone else got there first. No locks, no race conditions.
 * Every institution-facing lookup includes the institution id: tenant isolation is part of the query.
 */
public interface InstitutionNoticeRepository extends JpaRepository<InstitutionNotice, Long> {

    interface StatusCount {
        NoticeStatus getStatus();
        long getTotal();
    }

    Optional<InstitutionNotice> findByHolidayIdAndInstitutionId(Long holidayId, Long institutionId);

    boolean existsByHolidayIdAndInstitutionId(Long holidayId, Long institutionId);

    boolean existsByHolidayId(Long holidayId);

    boolean existsByHolidayIdAndStatusIn(Long holidayId, Collection<NoticeStatus> statuses);

    Page<InstitutionNotice> findByInstitutionIdAndStatusInOrderByDecidedAtDesc(
            Long institutionId, Collection<NoticeStatus> statuses, Pageable pageable);

    @Query("select n.status as status, count(n) as total from InstitutionNotice n "
            + "where n.holidayId = :holidayId group by n.status")
    List<StatusCount> countByStatus(@Param("holidayId") Long holidayId);

    @Query("select n from InstitutionNotice n, PublicHoliday h "
            + "where h.id = n.holidayId and h.dateAd = :date and n.status = :status")
    List<InstitutionNotice> findByHolidayDateAndStatus(@Param("date") LocalDate date,
                                                       @Param("status") NoticeStatus status);

    @Query("""
            select n from InstitutionNotice n, PublicHoliday h
             where h.id = n.holidayId and n.institutionId = :institutionId
               and n.status = com.college.bridge.holiday.domain.NoticeStatus.AWAITING_DECISION
               and h.dateAd >= :from
             order by h.dateAd
            """)
    List<InstitutionNotice> findAwaitingForInstitution(@Param("institutionId") Long institutionId,
                                                       @Param("from") LocalDate from);

    @Query("""
            select n from InstitutionNotice n
             where n.status = com.college.bridge.holiday.domain.NoticeStatus.APPROVED
               and n.nextAttemptAt <= :now
             order by n.nextAttemptAt
            """)
    List<InstitutionNotice> findDueForPublishing(@Param("now") Instant now, Pageable pageable);

    /** AWAITING_DECISION -> APPROVED for this institution only. First caller wins. */
    @Transactional
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            update InstitutionNotice n
               set n.status = com.college.bridge.holiday.domain.NoticeStatus.APPROVED,
                   n.approvedVariant = :variant, n.finalTitle = :title, n.finalBody = :body,
                   n.notifyStudents = :students, n.notifyTeachers = :teachers,
                   n.decidedBy = :userId, n.decidedAt = :now, n.nextAttemptAt = :now, n.updatedAt = :now
             where n.holidayId = :holidayId and n.institutionId = :institutionId
               and n.status = com.college.bridge.holiday.domain.NoticeStatus.AWAITING_DECISION
            """)
    int approveIfAwaiting(@Param("holidayId") Long holidayId, @Param("institutionId") Long institutionId,
                          @Param("variant") NoticeVariant variant, @Param("title") String title,
                          @Param("body") String body, @Param("students") boolean students,
                          @Param("teachers") boolean teachers, @Param("userId") Long userId,
                          @Param("now") Instant now);

    /** AWAITING_DECISION -> REJECTED. */
    @Transactional
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            update InstitutionNotice n
               set n.status = com.college.bridge.holiday.domain.NoticeStatus.REJECTED,
                   n.decidedBy = :userId, n.decidedAt = :now, n.updatedAt = :now
             where n.holidayId = :holidayId and n.institutionId = :institutionId
               and n.status = com.college.bridge.holiday.domain.NoticeStatus.AWAITING_DECISION
            """)
    int rejectIfAwaiting(@Param("holidayId") Long holidayId, @Param("institutionId") Long institutionId,
                         @Param("userId") Long userId, @Param("now") Instant now);

    /** AWAITING_DECISION -> EXPIRED for every holiday whose date has passed. No action = no announcement. */
    @Transactional
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            update InstitutionNotice n
               set n.status = com.college.bridge.holiday.domain.NoticeStatus.EXPIRED, n.updatedAt = :now
             where n.status = com.college.bridge.holiday.domain.NoticeStatus.AWAITING_DECISION
               and n.holidayId in (select h.id from PublicHoliday h where h.dateAd < :today)
            """)
    int expireOverdue(@Param("today") LocalDate today, @Param("now") Instant now);

    /** APPROVED -> PUBLISHING (counts the attempt). Only one server gets 1. */
    @Transactional
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            update InstitutionNotice n
               set n.status = com.college.bridge.holiday.domain.NoticeStatus.PUBLISHING,
                   n.publishAttempts = n.publishAttempts + 1, n.updatedAt = :now
             where n.id = :id
               and n.status = com.college.bridge.holiday.domain.NoticeStatus.APPROVED
            """)
    int claimForPublishing(@Param("id") Long id, @Param("now") Instant now);

    /** PUBLISHING -> PUBLISHED. */
    @Transactional
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            update InstitutionNotice n
               set n.status = com.college.bridge.holiday.domain.NoticeStatus.PUBLISHED,
                   n.publishedAt = :now, n.lastError = null, n.updatedAt = :now
             where n.id = :id
               and n.status = com.college.bridge.holiday.domain.NoticeStatus.PUBLISHING
            """)
    int markPublished(@Param("id") Long id, @Param("now") Instant now);

    /** PUBLISHING -> APPROVED after a retryable failure; the publisher tries again at nextAttemptAt. */
    @Transactional
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            update InstitutionNotice n
               set n.status = com.college.bridge.holiday.domain.NoticeStatus.APPROVED,
                   n.lastError = :error, n.nextAttemptAt = :nextAttemptAt, n.updatedAt = :now
             where n.id = :id
               and n.status = com.college.bridge.holiday.domain.NoticeStatus.PUBLISHING
            """)
    int returnToApproved(@Param("id") Long id, @Param("error") String error,
                         @Param("nextAttemptAt") Instant nextAttemptAt, @Param("now") Instant now);

    /** PUBLISHING -> FAILED when attempts are exhausted (the notice stays official and visible in the app). */
    @Transactional
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            update InstitutionNotice n
               set n.status = com.college.bridge.holiday.domain.NoticeStatus.FAILED,
                   n.lastError = :error, n.updatedAt = :now
             where n.id = :id
               and n.status = com.college.bridge.holiday.domain.NoticeStatus.PUBLISHING
            """)
    int markFailed(@Param("id") Long id, @Param("error") String error, @Param("now") Instant now);

    /** Rescues rows stuck in PUBLISHING because a server crashed mid-send (stale lease recovery). */
    @Transactional
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            update InstitutionNotice n
               set n.status = com.college.bridge.holiday.domain.NoticeStatus.APPROVED,
                   n.nextAttemptAt = :now, n.updatedAt = :now
             where n.status = com.college.bridge.holiday.domain.NoticeStatus.PUBLISHING
               and n.updatedAt < :cutoff
            """)
    int reclaimStalePublishing(@Param("cutoff") Instant cutoff, @Param("now") Instant now);
}
