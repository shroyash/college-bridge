package com.college.bridge.academic.repository;

import com.college.bridge.academic.entity.Subject;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SubjectRepository extends JpaRepository<Subject, Long> {

    @EntityGraph(attributePaths = {"academicLevel", "academicLevel.program", "assignments", "assignments.teacher", "assignments.teacher.user"})
    List<Subject> findByAcademicLevel_LevelId(Long levelId);

    @EntityGraph(attributePaths = {"academicLevel", "academicLevel.program"})
    List<Subject> findByAcademicLevel_Program_Institution_InstitutionId(Long institutionId);

    @EntityGraph(attributePaths = {"academicLevel", "academicLevel.program"})
    Optional<Subject> findBySubjectIdAndAcademicLevel_Program_Institution_InstitutionId(Long subjectId, Long institutionId);

    boolean existsByAcademicLevel_LevelIdAndName(Long levelId, String name);

    @EntityGraph(attributePaths = {"academicLevel", "academicLevel.program"})
    List<Subject> findByAcademicLevel_Program_Institution_InstitutionIdAndNameContainingIgnoreCase(Long institutionId, String name);

    long countByAcademicLevel_Program_Institution_InstitutionId(Long institutionId);

    List<Subject>
    findByAcademicLevel_LevelIdAndAcademicLevel_Program_Institution_InstitutionId(
            Long levelId,
            Long institutionId
    );

    @Query("""
    SELECT s
    FROM Subject s
    JOIN FETCH s.academicLevel al
    JOIN FETCH al.program p
    WHERE s.subjectId = :subjectId
      AND p.institution.institutionId = :tenantId
""")
    Optional<Subject> findSubjectDetails(
            @Param("subjectId") Long subjectId,
            @Param("tenantId") Long tenantId
    );

}
