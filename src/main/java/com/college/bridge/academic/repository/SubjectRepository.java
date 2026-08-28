package com.college.bridge.academic.repository;

import com.college.bridge.academic.entity.Subject;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;

public interface SubjectRepository extends JpaRepository<Subject, Long> {

    @EntityGraph(attributePaths = {"assignments", "assignments.teacher", "assignments.teacher.user"})
    List<Subject> findByInstitution_InstitutionIdAndFacultyAndSemester(Long institutionId, String faculty, Integer semester);

    boolean existsByInstitution_InstitutionIdAndNameAndFacultyAndSemester(Long institutionId, String name, String faculty, Integer semester);

    List<Subject> findByInstitution_InstitutionIdAndNameContainingIgnoreCase(Long institutionId, String name);

    List<Subject> findByInstitution_InstitutionId(Long institutionId);

    Optional<Subject> findBySubjectIdAndInstitution_InstitutionId(Long subjectId, Long institutionId);

    long countByInstitution_InstitutionId(Long institutionId);
}
