package com.college.bridge.academic.repository;

import com.college.bridge.academic.entity.AcademicProgram;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AcademicProgramRepository extends JpaRepository<AcademicProgram, Long> {

    List<AcademicProgram> findByInstitution_InstitutionId(Long institutionId);

    Optional<AcademicProgram> findByProgramIdAndInstitution_InstitutionId(Long programId, Long institutionId);

    Optional<AcademicProgram> findByInstitution_InstitutionIdAndCode(Long institutionId, String code);

    boolean existsByInstitution_InstitutionIdAndCode(Long institutionId, String code);

    boolean existsByInstitution_InstitutionIdAndName(Long institutionId, String name);

    long countByInstitution_InstitutionId(Long institutionId);
}
