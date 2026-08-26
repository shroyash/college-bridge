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

    @Query("SELECT ac FROM AcademicClass ac WHERE ac.institution.institutionId = :institutionId " +
           "AND (:faculty IS NULL OR :faculty = '' OR LOWER(ac.faculty) = LOWER(:faculty)) " +
           "AND (:semester IS NULL OR ac.semester = :semester) " +
           "AND (:search IS NULL OR :search = '' OR LOWER(ac.displayName) LIKE LOWER(CONCAT('%', :search, '%')) OR LOWER(ac.faculty) LIKE LOWER(CONCAT('%', :search, '%')))")
    List<AcademicClass> findClassesFiltered(
            @org.springframework.data.repository.query.Param("institutionId") Long institutionId,
            @org.springframework.data.repository.query.Param("faculty") String faculty,
            @org.springframework.data.repository.query.Param("semester") Integer semester,
            @org.springframework.data.repository.query.Param("search") String search
    );
}
