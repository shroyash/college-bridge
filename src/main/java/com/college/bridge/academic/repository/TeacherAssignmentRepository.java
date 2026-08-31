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
import java.util.Optional;

public interface TeacherAssignmentRepository extends JpaRepository<TeacherAssignment, Long> {

    @EntityGraph(attributePaths = {"subject", "subject.academicLevel", "subject.academicLevel.program"})
    List<TeacherAssignment> findByTeacherTeacherId(Long teacherId);

    @EntityGraph(attributePaths = {"subject", "subject.academicLevel", "subject.academicLevel.program"})
    List<TeacherAssignment> findByTeacher_TeacherId(Long teacherId);

    @EntityGraph(attributePaths = {"subject", "subject.academicLevel", "subject.academicLevel.program"})
    List<TeacherAssignment> findByTeacher_TeacherIdAndSubject_AcademicLevel_Program_Institution_InstitutionId(Long teacherId, Long tenantId);

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
    Optional<TeacherInfoProjection> findTeacherInfo(
            @Param("subjectId") Long subjectId
    );

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
}