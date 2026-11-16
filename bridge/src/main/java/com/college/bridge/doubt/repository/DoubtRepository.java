package com.college.bridge.doubt.repository;

import com.college.bridge.doubt.entity.Doubt;
import com.college.bridge.doubt.entity.DoubtStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface DoubtRepository extends JpaRepository<Doubt, Long> {


    @Query("""
        SELECT d
        FROM Doubt d
        JOIN FETCH d.student s
        JOIN FETCH d.subject sub
        JOIN sub.academicLevel al
        JOIN al.program p
        WHERE p.institution.institutionId = :tenantId
        ORDER BY d.createdAt DESC
    """)
    Page<Doubt> findAllByTenant(
            @Param("tenantId") Long tenantId,
            Pageable pageable
    );

    @Query("""
        SELECT d
        FROM Doubt d
        JOIN FETCH d.student s
        JOIN FETCH d.subject sub
        JOIN sub.academicLevel al
        JOIN al.program p
        WHERE d.student.studentId = :studentId
          AND p.institution.institutionId = :tenantId
        ORDER BY d.createdAt DESC
    """)
    Page<Doubt> findAllByStudentAndTenant(
            @Param("studentId") Long studentId,
            @Param("tenantId") Long tenantId,
            Pageable pageable
    );

    @Modifying
    @Query("""
        UPDATE Doubt d
        SET d.status = :status
        WHERE d.doubtId = :doubtId
          AND d.subject.subjectId IN (
              SELECT s.subjectId
              FROM Subject s
              JOIN s.academicLevel al
              JOIN al.program p
              WHERE p.institution.institutionId = :tenantId
          )
    """)
    int updateStatus(
            @Param("doubtId") Long doubtId,
            @Param("tenantId") Long tenantId,
            @Param("status") DoubtStatus status
    );



    @Query("""
        SELECT d
        FROM Doubt d
        JOIN FETCH d.student st
        JOIN FETCH d.subject s
        JOIN FETCH s.academicLevel al
        JOIN FETCH al.program p
        WHERE d.doubtId = :doubtId
          AND p.institution.institutionId = :tenantId
    """)
    Optional<Doubt> findByIdAndTenant(
            @Param("doubtId") Long doubtId,
            @Param("tenantId") Long tenantId
    );

    @Query(
            value = """
            SELECT d
            FROM Doubt d
            JOIN FETCH d.student st
            JOIN FETCH st.user studentUser
            JOIN FETCH d.subject s
            JOIN s.academicLevel al
            JOIN al.program p
            WHERE p.institution.institutionId = :tenantId
              AND (:subjectId IS NULL OR s.subjectId = :subjectId)
              AND EXISTS (
                  SELECT 1
                  FROM SubjectEnrollment se
                  WHERE se.student.studentId = :studentId
                    AND se.subject.subjectId = s.subjectId
                    AND se.status =
                        com.college.bridge.academic.entity.ClassStatus.ACTIVE
              )
              AND (
                  :search IS NULL
                  OR LOWER(d.question) LIKE LOWER(CONCAT('%', :search, '%'))
                  OR LOWER(s.name) LIKE LOWER(CONCAT('%', :search, '%'))
              )
            ORDER BY d.createdAt DESC
            """,
            countQuery = """
            SELECT COUNT(d)
            FROM Doubt d
            JOIN d.subject s
            JOIN s.academicLevel al
            JOIN al.program p
            WHERE p.institution.institutionId = :tenantId
              AND (:subjectId IS NULL OR s.subjectId = :subjectId)
              AND EXISTS (
                  SELECT 1
                  FROM SubjectEnrollment se
                  WHERE se.student.studentId = :studentId
                    AND se.subject.subjectId = s.subjectId
                    AND se.status =
                        com.college.bridge.academic.entity.ClassStatus.ACTIVE
              )
              AND (
                  :search IS NULL
                  OR LOWER(d.question) LIKE LOWER(CONCAT('%', :search, '%'))
                  OR LOWER(s.name) LIKE LOWER(CONCAT('%', :search, '%'))
              )
            """
    )
    Page<Doubt> findAccessibleForStudent(
            @Param("studentId") Long studentId,
            @Param("subjectId") Long subjectId,
            @Param("tenantId") Long tenantId,
            @Param("search") String search,
            Pageable pageable
    );

    @Query(
            value = """
            SELECT d
            FROM Doubt d
            JOIN FETCH d.student st
            JOIN FETCH st.user studentUser
            JOIN FETCH d.subject s
            JOIN s.academicLevel al
            JOIN al.program p
            WHERE p.institution.institutionId = :tenantId
              AND (:subjectId IS NULL OR s.subjectId = :subjectId)
              AND EXISTS (
                  SELECT 1
                  FROM TeacherAssignment ta
                  JOIN ta.teacher t
                  JOIN t.user teacherUser
                  WHERE t.teacherId = :teacherId
                    AND teacherUser.institution.institutionId = :tenantId
                    AND ta.subject.subjectId = s.subjectId
              )
              AND (
                  :search IS NULL
                  OR LOWER(d.question) LIKE LOWER(CONCAT('%', :search, '%'))
                  OR LOWER(s.name) LIKE LOWER(CONCAT('%', :search, '%'))
              )
            ORDER BY d.createdAt DESC
            """,
            countQuery = """
            SELECT COUNT(d)
            FROM Doubt d
            JOIN d.subject s
            JOIN s.academicLevel al
            JOIN al.program p
            WHERE p.institution.institutionId = :tenantId
              AND (:subjectId IS NULL OR s.subjectId = :subjectId)
              AND EXISTS (
                  SELECT 1
                  FROM TeacherAssignment ta
                  JOIN ta.teacher t
                  JOIN t.user teacherUser
                  WHERE t.teacherId = :teacherId
                    AND teacherUser.institution.institutionId = :tenantId
                    AND ta.subject.subjectId = s.subjectId
              )
              AND (
                  :search IS NULL
                  OR LOWER(d.question) LIKE LOWER(CONCAT('%', :search, '%'))
                  OR LOWER(s.name) LIKE LOWER(CONCAT('%', :search, '%'))
              )
            """
    )
    Page<Doubt> findAccessibleForTeacher(
            @Param("teacherId") Long teacherId,
            @Param("subjectId") Long subjectId,
            @Param("tenantId") Long tenantId,
            @Param("search") String search,
            Pageable pageable
    );

    @Query(
            value = """
            SELECT d
            FROM Doubt d
            JOIN FETCH d.student st
            JOIN FETCH st.user studentUser
            JOIN FETCH d.subject s
            JOIN s.academicLevel al
            JOIN al.program p
            WHERE p.institution.institutionId = :tenantId
              AND (:subjectId IS NULL OR s.subjectId = :subjectId)
              AND (
                  :search IS NULL
                  OR LOWER(d.question) LIKE LOWER(CONCAT('%', :search, '%'))
                  OR LOWER(s.name) LIKE LOWER(CONCAT('%', :search, '%'))
              )
            ORDER BY d.createdAt DESC
            """,
            countQuery = """
            SELECT COUNT(d)
            FROM Doubt d
            JOIN d.subject s
            JOIN s.academicLevel al
            JOIN al.program p
            WHERE p.institution.institutionId = :tenantId
              AND (:subjectId IS NULL OR s.subjectId = :subjectId)
              AND (
                  :search IS NULL
                  OR LOWER(d.question) LIKE LOWER(CONCAT('%', :search, '%'))
                  OR LOWER(s.name) LIKE LOWER(CONCAT('%', :search, '%'))
              )
            """
    )
    Page<Doubt> findAccessibleForAdmin(
            @Param("subjectId") Long subjectId,
            @Param("tenantId") Long tenantId,
            @Param("search") String search,
            Pageable pageable
    );

    @Query("""
        SELECT d
        FROM Doubt d
        JOIN FETCH d.student st
        JOIN FETCH st.user studentUser
        JOIN FETCH d.subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE d.doubtId = :doubtId
          AND p.institution.institutionId = :tenantId
          AND EXISTS (
              SELECT 1
              FROM SubjectEnrollment se
              WHERE se.student.studentId = :studentId
                AND se.subject.subjectId = s.subjectId
                AND se.status =
                    com.college.bridge.academic.entity.ClassStatus.ACTIVE
          )
    """)
    Optional<Doubt> findAccessibleByIdForStudent(
            @Param("doubtId") Long doubtId,
            @Param("studentId") Long studentId,
            @Param("tenantId") Long tenantId
    );

    @Query("""
        SELECT d
        FROM Doubt d
        JOIN FETCH d.student st
        JOIN FETCH st.user studentUser
        JOIN FETCH d.subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE d.doubtId = :doubtId
          AND p.institution.institutionId = :tenantId
          AND EXISTS (
              SELECT 1
              FROM TeacherAssignment ta
              JOIN ta.teacher t
              JOIN t.user teacherUser
              WHERE t.teacherId = :teacherId
                AND teacherUser.institution.institutionId = :tenantId
                AND ta.subject.subjectId = s.subjectId
          )
    """)
    Optional<Doubt> findAccessibleByIdForTeacher(
            @Param("doubtId") Long doubtId,
            @Param("teacherId") Long teacherId,
            @Param("tenantId") Long tenantId
    );

    @Query("""
        SELECT d
        FROM Doubt d
        JOIN FETCH d.student st
        JOIN FETCH st.user studentUser
        JOIN FETCH d.subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE d.doubtId = :doubtId
          AND p.institution.institutionId = :tenantId
    """)
    Optional<Doubt> findAccessibleByIdForAdmin(
            @Param("doubtId") Long doubtId,
            @Param("tenantId") Long tenantId
    );

    @Query("""
        SELECT COUNT(d)
        FROM Doubt d
        JOIN d.subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE (:subjectId IS NULL OR s.subjectId = :subjectId)
          AND p.institution.institutionId = :tenantId
    """)
    long countTotalBySubjectAndTenant(
            @Param("subjectId") Long subjectId,
            @Param("tenantId") Long tenantId
    );

    @Query("""
        SELECT COUNT(d)
        FROM Doubt d
        JOIN d.subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE (:subjectId IS NULL OR s.subjectId = :subjectId)
          AND p.institution.institutionId = :tenantId
          AND (d.status = com.college.bridge.doubt.entity.DoubtStatus.ANSWERED OR d.status = com.college.bridge.doubt.entity.DoubtStatus.RESOLVED)
    """)
    long countSolvedBySubjectAndTenant(
            @Param("subjectId") Long subjectId,
            @Param("tenantId") Long tenantId
    );

    @Query("""
        SELECT COUNT(d)
        FROM Doubt d
        JOIN d.subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE (:subjectId IS NULL OR s.subjectId = :subjectId)
          AND p.institution.institutionId = :tenantId
          AND d.status = com.college.bridge.doubt.entity.DoubtStatus.OPEN
    """)
    long countUnsolvedBySubjectAndTenant(
            @Param("subjectId") Long subjectId,
            @Param("tenantId") Long tenantId
    );

    @Query("""
        SELECT COUNT(d)
        FROM Doubt d
        JOIN d.subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE (:subjectId IS NULL OR s.subjectId = :subjectId)
          AND p.institution.institutionId = :tenantId
          AND EXISTS (
              SELECT 1
              FROM TeacherAssignment ta
              JOIN ta.teacher t
              JOIN t.user teacherUser
              WHERE t.teacherId = :teacherId
                AND teacherUser.institution.institutionId = :tenantId
                AND ta.subject.subjectId = s.subjectId
          )
    """)
    long countTotalForTeacher(
            @Param("teacherId") Long teacherId,
            @Param("subjectId") Long subjectId,
            @Param("tenantId") Long tenantId
    );

    @Query("""
        SELECT COUNT(d)
        FROM Doubt d
        JOIN d.subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE (:subjectId IS NULL OR s.subjectId = :subjectId)
          AND p.institution.institutionId = :tenantId
          AND (d.status = com.college.bridge.doubt.entity.DoubtStatus.ANSWERED OR d.status = com.college.bridge.doubt.entity.DoubtStatus.RESOLVED)
          AND EXISTS (
              SELECT 1
              FROM TeacherAssignment ta
              JOIN ta.teacher t
              JOIN t.user teacherUser
              WHERE t.teacherId = :teacherId
                AND teacherUser.institution.institutionId = :tenantId
                AND ta.subject.subjectId = s.subjectId
          )
    """)
    long countSolvedForTeacher(
            @Param("teacherId") Long teacherId,
            @Param("subjectId") Long subjectId,
            @Param("tenantId") Long tenantId
    );

    @Query("""
        SELECT COUNT(d)
        FROM Doubt d
        JOIN d.subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE (:subjectId IS NULL OR s.subjectId = :subjectId)
          AND p.institution.institutionId = :tenantId
          AND d.status = com.college.bridge.doubt.entity.DoubtStatus.OPEN
          AND EXISTS (
              SELECT 1
              FROM TeacherAssignment ta
              JOIN ta.teacher t
              JOIN t.user teacherUser
              WHERE t.teacherId = :teacherId
                AND teacherUser.institution.institutionId = :tenantId
                AND ta.subject.subjectId = s.subjectId
          )
    """)
    long countUnsolvedForTeacher(
            @Param("teacherId") Long teacherId,
            @Param("subjectId") Long subjectId,
            @Param("tenantId") Long tenantId
    );

    @Query("""
        SELECT COUNT(d)
        FROM Doubt d
        JOIN d.subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE (:subjectId IS NULL OR s.subjectId = :subjectId)
          AND p.institution.institutionId = :tenantId
          AND EXISTS (
              SELECT 1
              FROM SubjectEnrollment se
              WHERE se.student.studentId = :studentId
                AND se.subject.subjectId = s.subjectId
                AND se.status = com.college.bridge.academic.entity.ClassStatus.ACTIVE
          )
    """)
    long countTotalForStudent(
            @Param("studentId") Long studentId,
            @Param("subjectId") Long subjectId,
            @Param("tenantId") Long tenantId
    );

    @Query("""
        SELECT COUNT(d)
        FROM Doubt d
        JOIN d.subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE (:subjectId IS NULL OR s.subjectId = :subjectId)
          AND p.institution.institutionId = :tenantId
          AND (d.status = com.college.bridge.doubt.entity.DoubtStatus.ANSWERED OR d.status = com.college.bridge.doubt.entity.DoubtStatus.RESOLVED)
          AND EXISTS (
              SELECT 1
              FROM SubjectEnrollment se
              WHERE se.student.studentId = :studentId
                AND se.subject.subjectId = s.subjectId
                AND se.status = com.college.bridge.academic.entity.ClassStatus.ACTIVE
          )
    """)
    long countSolvedForStudent(
            @Param("studentId") Long studentId,
            @Param("subjectId") Long subjectId,
            @Param("tenantId") Long tenantId
    );

    @Query("""
        SELECT COUNT(d)
        FROM Doubt d
        JOIN d.subject s
        JOIN s.academicLevel al
        JOIN al.program p
        WHERE (:subjectId IS NULL OR s.subjectId = :subjectId)
          AND p.institution.institutionId = :tenantId
          AND d.status = com.college.bridge.doubt.entity.DoubtStatus.OPEN
          AND EXISTS (
              SELECT 1
              FROM SubjectEnrollment se
              WHERE se.student.studentId = :studentId
                AND se.subject.subjectId = s.subjectId
                AND se.status = com.college.bridge.academic.entity.ClassStatus.ACTIVE
          )
    """)
    long countUnsolvedForStudent(
            @Param("studentId") Long studentId,
            @Param("subjectId") Long subjectId,
            @Param("tenantId") Long tenantId
    );
}
