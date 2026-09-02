package com.college.bridge.academic.repository;

import com.college.bridge.academic.entity.AcademicLevel;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AcademicLevelRepository extends JpaRepository<AcademicLevel, Long> {

    @EntityGraph(attributePaths = {"program", "program.institution"})
    List<AcademicLevel> findByProgram_ProgramIdAndDeletedFalse(Long programId);
    default List<AcademicLevel> findByProgram_ProgramId(Long programId) {
        return findByProgram_ProgramIdAndDeletedFalse(programId);
    }

    @EntityGraph(attributePaths = {"program", "program.institution"})
    List<AcademicLevel> findByProgram_Institution_InstitutionIdAndDeletedFalseAndProgram_DeletedFalse(Long institutionId);
    default List<AcademicLevel> findByProgram_Institution_InstitutionId(Long institutionId) {
        return findByProgram_Institution_InstitutionIdAndDeletedFalseAndProgram_DeletedFalse(institutionId);
    }

    @EntityGraph(attributePaths = {"program", "program.institution"})
    Optional<AcademicLevel> findByLevelIdAndProgram_Institution_InstitutionIdAndDeletedFalseAndProgram_DeletedFalse(Long levelId, Long institutionId);
    default Optional<AcademicLevel> findByLevelIdAndProgram_Institution_InstitutionId(Long levelId, Long institutionId) {
        return findByLevelIdAndProgram_Institution_InstitutionIdAndDeletedFalseAndProgram_DeletedFalse(levelId, institutionId);
    }

    Optional<AcademicLevel> findByProgram_ProgramIdAndLevelNumberAndDeletedFalse(Long programId, Integer levelNumber);
    default Optional<AcademicLevel> findByProgram_ProgramIdAndLevelNumber(Long programId, Integer levelNumber) {
        return findByProgram_ProgramIdAndLevelNumberAndDeletedFalse(programId, levelNumber);
    }

    boolean existsByProgram_ProgramIdAndLevelNumberAndDeletedFalse(Long programId, Integer levelNumber);
    default boolean existsByProgram_ProgramIdAndLevelNumber(Long programId, Integer levelNumber) {
        return existsByProgram_ProgramIdAndLevelNumberAndDeletedFalse(programId, levelNumber);
    }

    boolean existsByProgram_ProgramIdAndNameAndDeletedFalse(Long programId, String name);
    default boolean existsByProgram_ProgramIdAndName(Long programId, String name) {
        return existsByProgram_ProgramIdAndNameAndDeletedFalse(programId, name);
    }

    long countByProgram_Institution_InstitutionIdAndDeletedFalseAndProgram_DeletedFalse(Long institutionId);
    default long countByProgram_Institution_InstitutionId(Long institutionId) {
        return countByProgram_Institution_InstitutionIdAndDeletedFalseAndProgram_DeletedFalse(institutionId);
    }
}
