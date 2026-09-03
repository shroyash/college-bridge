package com.college.bridge.academic.repository;

import com.college.bridge.academic.dto.TeacherInfoProjection;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.entity.TeacherAssignment;
import com.college.bridge.auth.entity.Teacher;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Map;
import java.util.Optional;

public interface TeacherAssignmentRepository extends JpaRepository<TeacherAssignment, Long> {


    @EntityGraph(attributePaths = {"subject", "subject.academicLevel", "subject.academicLevel.program"})
    List<TeacherAssignment> findByTeacher_TeacherIdAndSubject_AcademicLevel_Program_Institution_InstitutionId(
            Long teacherId,
            Long tenantId
    );


    @EntityGraph(attributePaths = {"subject", "subject.academicLevel", "subject.academicLevel.program"})
    List<TeacherAssignment> findByTeacher_TeacherId(Long teacherId);

    boolean existsByTeacherAndSubject(Teacher teacher, Subject subject);

    boolean existsByTeacher_TeacherIdAndSubject_SubjectId(Long teacherId, Long subjectId);

    boolean existsByTeacher_TeacherIdAndSubject_AcademicLevel_LevelId(Long teacherId, Long levelId);

    void deleteByTeacherTeacherId(Long teacherId);

    @Query("""
    SELECT
        t.teacherId AS teacherId,
        u.userId AS userId,
        u.name AS name,
        u.email AS email
    FROM TeacherAssignment ta
    JOIN ta.teacher t
    JOIN t.user u
    WHERE ta.subject.subjectId = :subjectId
""")
    Optional<TeacherInfoProjection> findTeacherInfo(@Param("subjectId") Long subjectId);

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
    JOIN FETCH ta.teacher t
    JOIN FETCH t.user u
    WHERE ta.subject.subjectId IN :subjectIds
""")
    List<TeacherAssignment> findBySubjectIds(@Param("subjectIds") List<Long> subjectIds);


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