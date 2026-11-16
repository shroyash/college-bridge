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

    @EntityGraph(attributePaths = {"teacher", "subject"})
    List<TeacherAssignment> findBySubject_SubjectIdIn(List<Long> subjectIds);

    @EntityGraph(attributePaths = {"teacher", "subject"})
    @Query("""
        SELECT ta FROM TeacherAssignment ta
        JOIN ta.subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE s.subjectId IN :subjectIds
          AND p.institution.institutionId = :tenantId
          AND s.deleted = false
    """)
    List<TeacherAssignment> findBySubject_SubjectIdInAndTenantId(
            @Param("subjectIds") List<Long> subjectIds,
            @Param("tenantId") Long tenantId
    );

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
        SELECT COUNT(ta) > 0
        FROM TeacherAssignment ta
        JOIN ta.teacher t
        JOIN t.user u
        JOIN ta.subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE u.userId = :userId
          AND al.levelId = :levelId
          AND p.institution.institutionId = :tenantId
          AND s.deleted = false
          AND al.deleted = false
          AND p.deleted = false
    """)
    boolean existsAssignmentForUserAndLevel(
            @Param("userId") Long userId,
            @Param("levelId") Long levelId,
            @Param("tenantId") Long tenantId
    );

    @Query("""
        SELECT COUNT(DISTINCT se.student.user.userId)
        FROM SubjectEnrollment se
        JOIN se.subject s
        JOIN TeacherAssignment ta ON ta.subject = s
        JOIN ta.teacher t
        WHERE t.user.userId = :teacherUserId
          AND se.student.user.userId IN :userIds
          AND se.student.user.institution.institutionId = :tenantId
          AND se.student.user.role = com.college.bridge.auth.entity.UserRole.STUDENT
          AND se.status = com.college.bridge.academic.entity.ClassStatus.ACTIVE
          AND s.deleted = false
    """)
    long countAuthorizedStudentsForTeacher(
            @Param("teacherUserId") Long teacherUserId,
            @Param("userIds") List<Long> userIds,
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

    @Query("""
        SELECT CASE WHEN COUNT(ta) > 0 THEN true ELSE false END
        FROM TeacherAssignment ta
        JOIN ta.teacher t
        JOIN t.user u
        JOIN ta.subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE t.teacherId = :teacherId
          AND s.subjectId = :subjectId
          AND u.institution.institutionId = :tenantId
          AND p.institution.institutionId = :tenantId
          AND s.deleted = false
          AND al.deleted = false
          AND p.deleted = false
    """)
    boolean existsByTeacherSubjectAndTenant(
            @Param("teacherId") Long teacherId,
            @Param("subjectId") Long subjectId,
            @Param("tenantId") Long tenantId
    );
}
