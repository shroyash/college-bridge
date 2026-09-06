package com.college.bridge.academic.repository;

import com.college.bridge.academic.entity.TeacherAssignment;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface TeacherAssignmentRepository extends JpaRepository<TeacherAssignment, Long> {

    @EntityGraph(attributePaths = {"subject", "subject.academicLevel", "subject.academicLevel.program"})
    @Query("""
        SELECT ta FROM TeacherAssignment ta
        JOIN ta.teacher t
        JOIN ta.subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE t.teacherId = :teacherId
          AND p.institution.institutionId = :tenantId
          AND s.deleted = false
          AND al.deleted = false
          AND p.deleted = false
    """)
    List<TeacherAssignment> findActiveByTeacherIdAndInstitutionId(
            @Param("teacherId") Long teacherId,
            @Param("tenantId") Long tenantId
    );

    @EntityGraph(attributePaths = {"subject", "subject.academicLevel", "subject.academicLevel.program"})
    List<TeacherAssignment> findByTeacher_TeacherId(Long teacherId);

    void deleteByTeacherTeacherId(Long teacherId);

    Optional<TeacherAssignment> findFirstBySubject_SubjectId(Long subjectId);

    @Query("""
    SELECT COUNT(ta) > 0
    FROM TeacherAssignment ta
    JOIN ta.teacher t
    JOIN t.user u
    JOIN ta.subject s
    JOIN s.academicLevel al
    JOIN al.program p
    WHERE s.subjectId = :subjectId
      AND u.userId = :userId
      AND p.institution.institutionId = :tenantId
""")
    boolean existsAssignmentForUser(
            @Param("subjectId") Long subjectId,
            @Param("userId") Long userId,
            @Param("tenantId") Long tenantId
    );

    @Query("""
    SELECT ta FROM TeacherAssignment ta
    JOIN ta.subject s
    JOIN s.academicLevel al
    JOIN al.program p
    WHERE ta.assignmentId = :assignmentId
      AND p.institution.institutionId = :tenantId
""")
    Optional<TeacherAssignment> findByAssignmentIdAndTenant(
            @Param("assignmentId") Long assignmentId,
            @Param("tenantId") Long tenantId
    );
}