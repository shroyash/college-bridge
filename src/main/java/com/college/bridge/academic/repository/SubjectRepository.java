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
    default List<Subject> findByAcademicLevel_LevelId(Long levelId) {
        return findByAcademicLevel_LevelIdAndDeletedFalse(levelId);
    }

    @EntityGraph(attributePaths = {"academicLevel", "academicLevel.program"})
    List<Subject> findByAcademicLevel_Program_Institution_InstitutionIdAndDeletedFalseAndAcademicLevel_DeletedFalseAndAcademicLevel_Program_DeletedFalse(Long institutionId);
    default List<Subject> findByAcademicLevel_Program_Institution_InstitutionId(Long institutionId) {
        return findByAcademicLevel_Program_Institution_InstitutionIdAndDeletedFalseAndAcademicLevel_DeletedFalseAndAcademicLevel_Program_DeletedFalse(institutionId);
    }

    @EntityGraph(attributePaths = {"academicLevel", "academicLevel.program"})
    Optional<Subject> findBySubjectIdAndAcademicLevel_Program_Institution_InstitutionIdAndDeletedFalseAndAcademicLevel_DeletedFalseAndAcademicLevel_Program_DeletedFalse(Long subjectId, Long institutionId);
    default Optional<Subject> findBySubjectIdAndAcademicLevel_Program_Institution_InstitutionId(Long subjectId, Long institutionId) {
        return findBySubjectIdAndAcademicLevel_Program_Institution_InstitutionIdAndDeletedFalseAndAcademicLevel_DeletedFalseAndAcademicLevel_Program_DeletedFalse(subjectId, institutionId);
    }

    boolean existsByAcademicLevel_LevelIdAndNameAndDeletedFalse(Long levelId, String name);
    default boolean existsByAcademicLevel_LevelIdAndName(Long levelId, String name) {
        return existsByAcademicLevel_LevelIdAndNameAndDeletedFalse(levelId, name);
    }

    @EntityGraph(attributePaths = {"academicLevel", "academicLevel.program"})
    List<Subject> findByAcademicLevel_Program_Institution_InstitutionIdAndNameContainingIgnoreCaseAndDeletedFalseAndAcademicLevel_DeletedFalseAndAcademicLevel_Program_DeletedFalse(Long institutionId, String name);
    default List<Subject> findByAcademicLevel_Program_Institution_InstitutionIdAndNameContainingIgnoreCase(Long institutionId, String name) {
        return findByAcademicLevel_Program_Institution_InstitutionIdAndNameContainingIgnoreCaseAndDeletedFalseAndAcademicLevel_DeletedFalseAndAcademicLevel_Program_DeletedFalse(institutionId, name);
    }

    long countByAcademicLevel_Program_Institution_InstitutionIdAndDeletedFalseAndAcademicLevel_DeletedFalseAndAcademicLevel_Program_DeletedFalse(Long institutionId);
    default long countByAcademicLevel_Program_Institution_InstitutionId(Long institutionId) {
        return countByAcademicLevel_Program_Institution_InstitutionIdAndDeletedFalseAndAcademicLevel_DeletedFalseAndAcademicLevel_Program_DeletedFalse(institutionId);
    }

    List<Subject> findByAcademicLevel_LevelIdAndAcademicLevel_Program_Institution_InstitutionIdAndDeletedFalseAndAcademicLevel_DeletedFalseAndAcademicLevel_Program_DeletedFalse(
            Long levelId,
            Long institutionId
    );
    default List<Subject> findByAcademicLevel_LevelIdAndAcademicLevel_Program_Institution_InstitutionId(Long levelId, Long institutionId) {
        return findByAcademicLevel_LevelIdAndAcademicLevel_Program_Institution_InstitutionIdAndDeletedFalseAndAcademicLevel_DeletedFalseAndAcademicLevel_Program_DeletedFalse(levelId, institutionId);
    }

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

    /**
     * Bulk soft-delete all non-deleted subjects belonging to any of the given level IDs.
     * Used during cascade soft-delete when a level (or its parent program) is deleted.
     * Returns the count of rows updated.
     */
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

    /**
     * Bulk-fetch subjects for given IDs scoped to a tenant.
     * Used to fix N+1: load all teacher assignments in one query after fetching a student's subjects.
     */
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

}
