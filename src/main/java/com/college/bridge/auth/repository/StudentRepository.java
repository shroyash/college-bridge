package com.college.bridge.auth.repository;

import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface StudentRepository extends JpaRepository<Student, Long> {
    Optional<Student> findByUser(User user);

    @EntityGraph(attributePaths = {"academicClass", "user"})
    Optional<Student> findByUser_UserId(Long userId);

    @EntityGraph(attributePaths = {"academicClass", "user"})
    Optional<Student> findByStudentId(Long studentId);

    List<Student> findByUser_UserIdIn(List<Long> userIds);

    @Query("SELECT COUNT(s) FROM Student s WHERE s.studentId IN :studentIds AND s.user.institution.institutionId = :tenantId")
    long countByStudentIdInAndTenantId(@Param("studentIds") List<Long> studentIds, @Param("tenantId") Long tenantId);

    @Modifying
    @Query("UPDATE Student s SET s.academicClass.classId = :targetClassId WHERE s.studentId IN :studentIds AND s.user.institution.institutionId = :tenantId")
    int bulkUpdateAcademicClass(
            @Param("studentIds") List<Long> studentIds,
            @Param("targetClassId") Long targetClassId,
            @Param("tenantId") Long tenantId
    );

    @EntityGraph(attributePaths = {"academicClass", "user"})
    List<Student> findByAcademicClass_ClassId(Long classId);

    @EntityGraph(attributePaths = {"user"})
    List<Student> findByUser_Institution_InstitutionIdAndAcademicClassIsNull(Long institutionId);

    long countByAcademicClass_ClassId(Long classId);

    @EntityGraph(attributePaths = {"academicClass", "user"})
    @Query("SELECT s FROM Student s WHERE s.user.institution.institutionId = :tenantId " +
           "AND (:faculty IS NULL OR s.academicClass.faculty = :faculty) " +
           "AND (:semester IS NULL OR s.academicClass.semester = :semester) " +
           "AND (:search IS NULL OR LOWER(s.user.name) LIKE LOWER(CONCAT('%', :search, '%')) OR LOWER(s.user.email) LIKE LOWER(CONCAT('%', :search, '%')))")
    Page<Student> findStudentsFiltered(
            @Param("tenantId") Long tenantId,
            @Param("faculty") String faculty,
            @Param("semester") Integer semester,
            @Param("search") String search,
            Pageable pageable
    );
}
