package com.college.bridge.academic.repository;

import com.college.bridge.academic.entity.AcademicLevel;
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
public interface AcademicLevelRepository extends JpaRepository<AcademicLevel, Long> {

    @EntityGraph(attributePaths = {"program", "program.institution"})
    List<AcademicLevel> findByProgram_ProgramIdAndDeletedFalse(Long programId);

    @EntityGraph(attributePaths = {"program", "program.institution"})
    @Query("""
        SELECT al FROM AcademicLevel al
        WHERE al.program.institution.institutionId = :institutionId
          AND al.deleted = false
          AND al.program.deleted = false
    """)
    List<AcademicLevel> findActiveByInstitutionId(@Param("institutionId") Long institutionId);

    @EntityGraph(attributePaths = {"program", "program.institution"})
    @Query("""
        SELECT al FROM AcademicLevel al
        WHERE al.levelId = :levelId
          AND al.program.institution.institutionId = :institutionId
          AND al.deleted = false
          AND al.program.deleted = false
    """)
    Optional<AcademicLevel> findActiveByIdAndInstitutionId(
            @Param("levelId") Long levelId,
            @Param("institutionId") Long institutionId
    );

    Optional<AcademicLevel> findByProgram_ProgramIdAndLevelNumberAndDeletedFalse(Long programId, Integer levelNumber);

    boolean existsByProgram_ProgramIdAndLevelNumberAndDeletedFalse(Long programId, Integer levelNumber);

    @Query("""
        SELECT COUNT(al) FROM AcademicLevel al
        WHERE al.program.institution.institutionId = :institutionId
          AND al.deleted = false
          AND al.program.deleted = false
    """)
    long countActiveByInstitutionId(@Param("institutionId") Long institutionId);

    /**
     * Bulk soft-delete all non-deleted levels belonging to the given program.
     * Used during cascade soft-delete when a program is deleted.
     * Returns the count of rows updated.
     */
    @Modifying
    @Query("""
        UPDATE AcademicLevel l
        SET l.deleted = true, l.deletedAt = :now
        WHERE l.program.programId = :programId
          AND l.deleted = false
    """)
    int softDeleteByProgramId(
            @Param("programId") Long programId,
            @Param("now") LocalDateTime now
    );

    /**
     * Returns the IDs of all non-deleted levels belonging to the given program.
     * Used to cascade soft-delete to subjects when a program is deleted.
     */
    @Query("SELECT l.levelId FROM AcademicLevel l WHERE l.program.programId = :programId AND l.deleted = false")
    List<Long> findLevelIdsByProgramId(@Param("programId") Long programId);
}
