package com.college.bridge.academic.repository;

import com.college.bridge.academic.dto.SubjectResponse;
import com.college.bridge.academic.entity.ClassStatus;
import com.college.bridge.academic.entity.SubjectEnrollment;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface SubjectEnrollmentRepository extends JpaRepository<SubjectEnrollment, Long> {

    @EntityGraph(attributePaths = {"student", "student.user"})
    List<SubjectEnrollment> findBySubject_SubjectId(Long subjectId);

    Optional<SubjectEnrollment> findBySubject_SubjectIdAndStudent_StudentId(Long subjectId, Long studentId);

    Optional<SubjectEnrollment> findBySubject_SubjectIdAndStudent_User_UserId(Long subjectId, Long userId);

    @Modifying
    @Query("DELETE FROM SubjectEnrollment se WHERE se.student.studentId IN :studentIds")
    int bulkDeleteByStudentIds(@Param("studentIds") List<Long> studentIds);

    @Modifying
    @Query(nativeQuery = true, value =
        "INSERT INTO subject_enrollments (student_id, subject_id, enrolled_at) " +
        "SELECT s.student_id, sub.subject_id, NOW() " +
        "FROM students s CROSS JOIN subjects sub " +
        "WHERE s.student_id IN (:studentIds) " +
        "  AND sub.level_id = :targetLevelId"
    )
    int bulkInsertEnrollmentsForTargetLevel(
            @Param("studentIds") List<Long> studentIds,
            @Param("targetLevelId") Long targetLevelId
    );

    @Query("""
    SELECT COUNT(se) > 0
    FROM SubjectEnrollment se
    JOIN se.student s
    JOIN s.user u
    JOIN se.subject sub
    JOIN sub.academicLevel al
    JOIN al.program p
    WHERE se.subject.subjectId = :subjectId
      AND u.userId = :userId
      AND p.institution.institutionId = :tenantId
""")
    boolean existsEnrollmentForUser(
            @Param("subjectId") Long subjectId,
            @Param("userId") Long userId,
            @Param("tenantId") Long tenantId
    );

    @Query("""
        SELECT se FROM SubjectEnrollment se
        JOIN se.student st
        JOIN st.user u
        WHERE st.studentId = :studentId
          AND u.institution.institutionId = :institutionId
    """)
    List<SubjectEnrollment> findActiveByStudentIdAndInstitutionId(
            @Param("studentId") Long studentId,
            @Param("institutionId") Long institutionId
    );

    @Query("""
    SELECT DISTINCT new com.college.bridge.academic.dto.SubjectResponse(
        s.subjectId,
        al.levelId,
        al.name,
        p.programId,
        p.name,
        s.name,
        s.code,
        s.creditHours,
        s.fcmTopicId,
        u.name
    )
    FROM Student st
    JOIN st.user studentUser
    LEFT JOIN SubjectEnrollment se ON se.student = st
    LEFT JOIN Subject s ON (s = se.subject OR (st.academicLevel IS NOT NULL AND s.academicLevel = st.academicLevel))
    LEFT JOIN s.academicLevel al
    LEFT JOIN al.program p
    LEFT JOIN s.assignments ta
    LEFT JOIN ta.teacher t
    LEFT JOIN t.user u
    WHERE st.studentId = :studentId
      AND studentUser.institution.institutionId = :tenantId
      AND s.subjectId IS NOT NULL
      AND s.deleted = false
      AND al.deleted = false
      AND p.deleted = false
""")
    List<SubjectResponse> findSubjectsForStudent(
            @Param("studentId") Long studentId,
            @Param("tenantId") Long tenantId
    );
    @Query("""
        SELECT CASE WHEN COUNT(se) > 0 THEN true ELSE false END
        FROM SubjectEnrollment se
        JOIN se.subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE se.student.studentId = :studentId
          AND s.subjectId = :subjectId
          AND p.institution.institutionId = :tenantId
          AND s.deleted = false
          AND al.deleted = false
          AND p.deleted = false
          AND se.status = :status
    """)
    boolean existsByStudentSubjectAndTenantAndStatus(
            @Param("studentId") Long studentId,
            @Param("subjectId") Long subjectId,
            @Param("tenantId") Long tenantId,
            @Param("status") ClassStatus status
    );

    @Query("""
        SELECT se
        FROM SubjectEnrollment se
        JOIN FETCH se.subject s
        JOIN FETCH s.academicLevel al
        JOIN FETCH al.program p
        WHERE se.student.studentId = :studentId
          AND s.subjectId = :subjectId
          AND p.institution.institutionId = :tenantId
          AND s.deleted = false
          AND al.deleted = false
          AND p.deleted = false
          AND se.status = :status
    """)
    Optional<SubjectEnrollment> findActiveEnrollment(
            @Param("studentId") Long studentId,
            @Param("subjectId") Long subjectId,
            @Param("tenantId") Long tenantId,
            @Param("status") ClassStatus status
    );
}
