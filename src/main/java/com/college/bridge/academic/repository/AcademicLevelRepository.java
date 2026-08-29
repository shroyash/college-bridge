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
    List<AcademicLevel> findByProgram_ProgramId(Long programId);

    @EntityGraph(attributePaths = {"program", "program.institution"})
    List<AcademicLevel> findByProgram_Institution_InstitutionId(Long institutionId);

    @EntityGraph(attributePaths = {"program", "program.institution"})
    Optional<AcademicLevel> findByLevelIdAndProgram_Institution_InstitutionId(Long levelId, Long institutionId);

    Optional<AcademicLevel> findByProgram_ProgramIdAndLevelNumber(Long programId, Integer levelNumber);

    boolean existsByProgram_ProgramIdAndLevelNumber(Long programId, Integer levelNumber);

    boolean existsByProgram_ProgramIdAndName(Long programId, String name);
}
