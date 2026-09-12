package com.college.bridge.academic.repository;

import com.college.bridge.academic.entity.Subject;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface SubjectRepository extends JpaRepository<Subject, Long> {

    @EntityGraph(attributePaths = {"academicLevel", "academicLevel.program", "assignments", "assignments.teacher", "assignments.teacher.user"})
    List<Subject> findByAcademicLevel_LevelIdAndDeletedFalse(Long levelId);

    @EntityGraph(attributePaths = {"academicLevel", "academicLevel.program", "assignments", "assignments.teacher", "assignments.teacher.user"})
    @Query("""
        SELECT DISTINCT s FROM Subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE p.institution.institutionId = :institutionId
          AND s.deleted = false
          AND al.deleted = false
          AND p.deleted = false
    """)
    List<Subject> findActiveByInstitutionId(@Param("institutionId") Long institutionId);

    @EntityGraph(attributePaths = {"academicLevel", "academicLevel.program"})
    @Query("""
        SELECT s FROM Subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE s.subjectId = :subjectId
          AND p.institution.institutionId = :institutionId
          AND s.deleted = false
          AND al.deleted = false
          AND p.deleted = false
    """)
    Optional<Subject> findActiveByIdAndInstitutionId(
            @Param("subjectId") Long subjectId,
            @Param("institutionId") Long institutionId
    );

    boolean existsByAcademicLevel_LevelIdAndNameAndDeletedFalse(Long levelId, String name);

    @EntityGraph(attributePaths = {"academicLevel", "academicLevel.program"})
    @Query("""
        SELECT s FROM Subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE p.institution.institutionId = :institutionId
          AND LOWER(s.name) LIKE LOWER(CONCAT('%', :name, '%'))
          AND s.deleted = false
          AND al.deleted = false
          AND p.deleted = false
    """)
    List<Subject> findActiveByInstitutionIdAndNameContaining(
            @Param("institutionId") Long institutionId,
            @Param("name") String name
    );

    @Query("""
        SELECT COUNT(s) FROM Subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE p.institution.institutionId = :institutionId
          AND s.deleted = false
          AND al.deleted = false
          AND p.deleted = false
    """)
    long countActiveByInstitutionId(@Param("institutionId") Long institutionId);

    @EntityGraph(attributePaths = {"academicLevel", "academicLevel.program", "assignments", "assignments.teacher", "assignments.teacher.user"})
    @Query("""
        SELECT DISTINCT s FROM Subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE al.levelId = :levelId
          AND p.institution.institutionId = :institutionId
          AND s.deleted = false
          AND al.deleted = false
          AND p.deleted = false
    """)
    List<Subject> findActiveByLevelIdAndInstitutionId(
            @Param("levelId") Long levelId,
            @Param("institutionId") Long institutionId
    );

    @Query("""
    SELECT s
    FROM Subject s
    JOIN FETCH s.academicLevel al
    JOIN FETCH al.program p
    WHERE s.subjectId = :subjectId
      AND p.institution.institutionId = :tenantId
      AND s.deleted = false
      AND al.deleted = false
      AND p.deleted = false
""")
    Optional<Subject> findSubjectDetails(
            @Param("subjectId") Long subjectId,
            @Param("tenantId") Long tenantId
    );

    @Modifying
    @Query("""
        UPDATE Subject s
        SET s.deleted = true, s.deletedAt = :now
        WHERE s.academicLevel.levelId IN :levelIds
          AND s.deleted = false
    """)
    int softDeleteByLevelIds(
            @Param("levelIds") List<Long> levelIds,
            @Param("now") LocalDateTime now
    );

    @Query("""
        SELECT s FROM Subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE s.subjectId IN :subjectIds
          AND p.institution.institutionId = :tenantId
          AND s.deleted = false
    """)
    List<Subject> findBySubjectIdsAndTenant(
            @Param("subjectIds") List<Long> subjectIds,
            @Param("tenantId") Long tenantId
    );
    @Query("""
    SELECT COUNT(s) > 0
    FROM Subject s
    JOIN s.academicLevel al
    JOIN al.program p
    WHERE s.subjectId = :subjectId
      AND p.institution.institutionId = :tenantId
      AND s.deleted = false
      AND al.deleted = false
      AND p.deleted = false
""")
    boolean existsActiveByIdAndInstitutionId(
            @Param("subjectId") Long subjectId,
            @Param("tenantId") Long tenantId
    );
}
