package com.college.bridge.academic.repository;

import com.college.bridge.academic.entity.SubjectEnrollment;
import com.college.bridge.auth.entity.Student;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface SubjectEnrollmentRepository extends JpaRepository<SubjectEnrollment, Long> {

    List<SubjectEnrollment> findByStudent(Student student);

    @Modifying
    @Query("DELETE FROM SubjectEnrollment se WHERE se.student.studentId IN :studentIds")
    int bulkDeleteByStudentIds(@Param("studentIds") List<Long> studentIds);

    @Modifying
    @Query(nativeQuery = true, value =
        "INSERT INTO subject_enrollments (student_id, subject_id, enrolled_at) " +
        "SELECT s.student_id, sub.subject_id, NOW() " +
        "FROM students s CROSS JOIN subjects sub " +
        "WHERE s.student_id IN (:studentIds) " +
        "  AND sub.institution_id = :tenantId " +
        "  AND sub.faculty = :targetFaculty " +
        "  AND sub.semester = :targetSemester"
    )
    int bulkInsertEnrollmentsForTargetClass(
            @Param("studentIds") List<Long> studentIds,
            @Param("tenantId") Long tenantId,
            @Param("targetFaculty") String targetFaculty,
            @Param("targetSemester") Integer targetSemester
    );
}
