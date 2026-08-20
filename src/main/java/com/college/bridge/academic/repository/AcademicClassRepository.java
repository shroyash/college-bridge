package com.college.bridge.academic.repository;

import com.college.bridge.academic.entity.AcademicClass;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface AcademicClassRepository extends JpaRepository<AcademicClass, Long> {

    Optional<AcademicClass> findByInstitution_InstitutionIdAndFacultyAndSemester(Long institutionId, String faculty, Integer semester);

    boolean existsByInstitution_InstitutionIdAndFacultyAndSemester(Long institutionId, String faculty, Integer semester);

    List<AcademicClass> findByInstitution_InstitutionId(Long institutionId);

    Optional<AcademicClass> findByClassIdAndInstitution_InstitutionId(Long classId, Long institutionId);

    @Query("SELECT DISTINCT ac.faculty FROM AcademicClass ac WHERE ac.institution.institutionId = :institutionId")
    List<String> findDistinctFacultiesByInstitutionId(Long institutionId);
}
