package com.college.bridge.academic.repository;

import com.college.bridge.academic.entity.Faculty;
import com.college.bridge.academic.entity.Subject;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SubjectRepository extends JpaRepository<Subject, Long> {

    List<Subject> findByFacultyAndSemester(Faculty faculty, Integer semester);

    boolean existsByNameAndFacultyAndSemester(String name, Faculty faculty, Integer semester);
}
