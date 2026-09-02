package com.college.bridge.academic.repository;

import com.college.bridge.academic.entity.AcademicProgram;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AcademicProgramRepository extends JpaRepository<AcademicProgram, Long> {

    List<AcademicProgram> findByInstitution_InstitutionIdAndDeletedFalse(Long institutionId);
    default List<AcademicProgram> findByInstitution_InstitutionId(Long institutionId) {
        return findByInstitution_InstitutionIdAndDeletedFalse(institutionId);
    }

    Optional<AcademicProgram> findByProgramIdAndInstitution_InstitutionIdAndDeletedFalse(Long programId, Long institutionId);
    default Optional<AcademicProgram> findByProgramIdAndInstitution_InstitutionId(Long programId, Long institutionId) {
        return findByProgramIdAndInstitution_InstitutionIdAndDeletedFalse(programId, institutionId);
    }

    Optional<AcademicProgram> findByProgramIdAndDeletedFalse(Long programId);

    Optional<AcademicProgram> findByInstitution_InstitutionIdAndCodeAndDeletedFalse(Long institutionId, String code);
    default Optional<AcademicProgram> findByInstitution_InstitutionIdAndCode(Long institutionId, String code) {
        return findByInstitution_InstitutionIdAndCodeAndDeletedFalse(institutionId, code);
    }

    boolean existsByInstitution_InstitutionIdAndCodeAndDeletedFalse(Long institutionId, String code);
    default boolean existsByInstitution_InstitutionIdAndCode(Long institutionId, String code) {
        return existsByInstitution_InstitutionIdAndCodeAndDeletedFalse(institutionId, code);
    }

    boolean existsByInstitution_InstitutionIdAndNameAndDeletedFalse(Long institutionId, String name);
    default boolean existsByInstitution_InstitutionIdAndName(Long institutionId, String name) {
        return existsByInstitution_InstitutionIdAndNameAndDeletedFalse(institutionId, name);
    }

    long countByInstitution_InstitutionIdAndDeletedFalse(Long institutionId);
    default long countByInstitution_InstitutionId(Long institutionId) {
        return countByInstitution_InstitutionIdAndDeletedFalse(institutionId);
    }
}
