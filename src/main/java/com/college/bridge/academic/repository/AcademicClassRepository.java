package com.college.bridge.academic.repository;

import com.college.bridge.academic.entity.AcademicClass;
import com.college.bridge.academic.entity.Faculty;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AcademicClassRepository extends JpaRepository<AcademicClass, Long> {

    Optional<AcademicClass> findByInstitution_InstitutionIdAndFacultyAndSemester(Long institutionId, Faculty faculty, Integer semester);

    boolean existsByInstitution_InstitutionIdAndFacultyAndSemester(Long institutionId, Faculty faculty, Integer semester);

    List<AcademicClass> findByInstitution_InstitutionId(Long institutionId);

    Optional<AcademicClass> findByClassIdAndInstitution_InstitutionId(Long classId, Long institutionId);
}
