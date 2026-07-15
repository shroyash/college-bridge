package com.college.bridge.academic.repository;

import com.college.bridge.academic.entity.AcademicClass;
import com.college.bridge.academic.entity.Faculty;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface AcademicClassRepository extends JpaRepository<AcademicClass, Long> {

    Optional<AcademicClass> findByFacultyAndSemester(Faculty faculty, Integer semester);

    boolean existsByFacultyAndSemester(Faculty faculty, Integer semester);
}
