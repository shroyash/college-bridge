package com.college.bridge.doubt.repository;

import com.college.bridge.doubt.dto.DoubtAnswerCountProjection;
import com.college.bridge.doubt.entity.DoubtAnswer;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface DoubtAnswerRepository
        extends JpaRepository<DoubtAnswer, Long> {

    @Query("""
        SELECT a
        FROM DoubtAnswer a
        JOIN FETCH a.answeredBy u
        WHERE a.doubt.doubtId = :doubtId
          AND a.doubt.subject.academicLevel.program.institution.institutionId = :tenantId
        ORDER BY a.createdAt ASC
    """)
    Page<DoubtAnswer> findAnswersByDoubtAndTenant(
            @Param("doubtId") Long doubtId,
            @Param("tenantId") Long tenantId,
            Pageable pageable
    );



    @Query("""
        SELECT COUNT(a)
        FROM DoubtAnswer a
        WHERE a.doubt.doubtId = :doubtId
          AND a.doubt.subject.academicLevel.program.institution.institutionId = :tenantId
    """)
    long countByDoubtAndTenant(
            @Param("doubtId") Long doubtId,
            @Param("tenantId") Long tenantId
    );

    @Query("""
        SELECT COUNT(a)
        FROM DoubtAnswer a
        WHERE a.doubt.doubtId = :doubtId
          AND a.isVerified = true
          AND a.doubt.subject.academicLevel.program.institution.institutionId = :tenantId
    """)
    long countVerifiedByDoubtAndTenant(
            @Param("doubtId") Long doubtId,
            @Param("tenantId") Long tenantId
    );

    @Query("""
        SELECT COUNT(a)
        FROM DoubtAnswer a
        WHERE a.doubt.doubtId = :doubtId
          AND a.isVerified = false
          AND a.doubt.subject.academicLevel.program.institution.institutionId = :tenantId
    """)
    long countUnverifiedByDoubtAndTenant(
            @Param("doubtId") Long doubtId,
            @Param("tenantId") Long tenantId
    );

    @Query("""
    SELECT a
    FROM DoubtAnswer a
    JOIN FETCH a.answeredBy u
    WHERE a.doubt.doubtId = :doubtId
      AND a.isVerified = :verified
      AND a.doubt.subject.academicLevel.program.institution.institutionId = :tenantId
    ORDER BY a.createdAt ASC
""")
    Page<DoubtAnswer> findAnswersByDoubtAndTenantAndVerified(
            @Param("doubtId") Long doubtId,
            @Param("tenantId") Long tenantId,
            @Param("verified") boolean verified,
            Pageable pageable
    );

    @Query(
            value = """
            SELECT a
            FROM DoubtAnswer a
            JOIN FETCH a.answeredBy u
            JOIN a.doubt d
            JOIN d.subject s
            JOIN s.academicLevel al
            JOIN al.program p
            WHERE d.doubtId = :doubtId
              AND p.institution.institutionId = :tenantId
              AND (:verified IS NULL OR a.isVerified = :verified)
            ORDER BY a.createdAt ASC
            """,
            countQuery = """
            SELECT COUNT(a)
            FROM DoubtAnswer a
            JOIN a.doubt d
            JOIN d.subject s
            JOIN s.academicLevel al
            JOIN al.program p
            WHERE d.doubtId = :doubtId
              AND p.institution.institutionId = :tenantId
              AND (:verified IS NULL OR a.isVerified = :verified)
            """
    )
    Page<DoubtAnswer> findAnswersByDoubtAndTenant(
            @Param("doubtId") Long doubtId,
            @Param("tenantId") Long tenantId,
            @Param("verified") Boolean verified,
            Pageable pageable
    );

    @Query("""
        SELECT a
        FROM DoubtAnswer a
        JOIN FETCH a.answeredBy u
        JOIN FETCH a.doubt d
        JOIN FETCH d.subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE a.answerId = :answerId
          AND d.doubtId = :doubtId
          AND p.institution.institutionId = :tenantId
    """)
    Optional<DoubtAnswer> findByIdAndDoubtAndTenant(
            @Param("answerId") Long answerId,
            @Param("doubtId") Long doubtId,
            @Param("tenantId") Long tenantId
    );

    @Query("""
        SELECT a
        FROM DoubtAnswer a
        JOIN FETCH a.answeredBy u
        JOIN FETCH a.doubt d
        JOIN FETCH d.subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE a.answerId = :answerId
          AND p.institution.institutionId = :tenantId
    """)
    Optional<DoubtAnswer> findByIdAndTenant(
            @Param("answerId") Long answerId,
            @Param("tenantId") Long tenantId
    );

    @Query("""
        SELECT a
        FROM DoubtAnswer a
        JOIN FETCH a.answeredBy u
        JOIN FETCH a.doubt d
        JOIN FETCH d.subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE d.doubtId = :doubtId
          AND p.institution.institutionId = :tenantId
        ORDER BY a.createdAt ASC
    """)
    List<DoubtAnswer> findAllByDoubtAndTenantList(
            @Param("doubtId") Long doubtId,
            @Param("tenantId") Long tenantId
    );

    @Query("""
        SELECT
            a.doubt.doubtId AS doubtId,
            COUNT(a.answerId) AS answerCount,
            SUM(
                CASE
                    WHEN a.isVerified = true THEN 1
                    ELSE 0
                END
            ) AS verifiedAnswerCount
        FROM DoubtAnswer a
        WHERE a.doubt.doubtId IN :doubtIds
          AND a.doubt.subject.academicLevel.program.institution.institutionId = :tenantId
        GROUP BY a.doubt.doubtId
    """)
    List<DoubtAnswerCountProjection> countByDoubtIdsAndTenant(
            @Param("doubtIds") List<Long> doubtIds,
            @Param("tenantId") Long tenantId
    );
}