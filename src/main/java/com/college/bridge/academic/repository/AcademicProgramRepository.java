package com.college.bridge.academic.repository;

import com.college.bridge.academic.entity.AcademicProgram;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AcademicProgramRepository extends JpaRepository<AcademicProgram, Long> {

    List<AcademicProgram> findByInstitution_InstitutionIdAndDeletedFalse(Long institutionId);

    Optional<AcademicProgram> findByProgramIdAndInstitution_InstitutionIdAndDeletedFalse(Long programId, Long institutionId);

    Optional<AcademicProgram> findByProgramIdAndDeletedFalse(Long programId);

    Optional<AcademicProgram> findByInstitution_InstitutionIdAndCodeAndDeletedFalse(Long institutionId, String code);

    boolean existsByInstitution_InstitutionIdAndCodeAndDeletedFalse(Long institutionId, String code);

    long countByInstitution_InstitutionIdAndDeletedFalse(Long institutionId);
}
