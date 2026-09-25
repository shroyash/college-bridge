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

    @EntityGraph(attributePaths = {"academicLevel", "academicLevel.program", "user"})
    Optional<Student> findByUser_UserId(Long userId);

    @EntityGraph(attributePaths = {"academicLevel", "academicLevel.program", "user"})
    Optional<Student> findByUser_UserIdAndUser_Institution_InstitutionId(Long userId, Long institutionId);

    @EntityGraph(attributePaths = {"academicLevel", "academicLevel.program", "user"})
    Optional<Student> findByStudentIdAndUser_Institution_InstitutionId(Long studentId, Long institutionId);

    @Modifying
    @Query("UPDATE Student s SET s.academicLevel = null WHERE s.academicLevel.levelId = :levelId")
    int clearAcademicLevel(@Param("levelId") Long levelId);

    List<Student> findByUser_UserIdIn(List<Long> userIds);

    @Query("SELECT COUNT(s) FROM Student s WHERE s.studentId IN :studentIds AND s.user.institution.institutionId = :tenantId")
    long countByStudentIdInAndTenantId(@Param("studentIds") List<Long> studentIds, @Param("tenantId") Long tenantId);

    @Modifying
    @Query("UPDATE Student s SET s.academicLevel.levelId = :targetLevelId WHERE s.studentId IN :studentIds AND s.user.institution.institutionId = :tenantId")
    int bulkUpdateAcademicLevel(
            @Param("studentIds") List<Long> studentIds,
            @Param("targetLevelId") Long targetLevelId,
            @Param("tenantId") Long tenantId
    );

    @EntityGraph(attributePaths = {"academicLevel", "academicLevel.program", "user"})
    List<Student> findByAcademicLevel_LevelIdAndUser_Institution_InstitutionId(
            Long levelId,
            Long institutionId
    );

    @EntityGraph(attributePaths = {"user"})
    List<Student> findByUser_Institution_InstitutionIdAndAcademicLevelIsNull(Long institutionId);

    long countByUser_Institution_InstitutionId(Long institutionId);

    @EntityGraph(attributePaths = {"academicLevel", "academicLevel.program", "user"})
    @Query("SELECT s FROM Student s WHERE s.user.institution.institutionId = :tenantId " +
           "AND (:programId IS NULL OR s.academicLevel.program.programId = :programId) " +
           "AND (:levelId IS NULL OR s.academicLevel.levelId = :levelId) " +
           "AND (:faculty IS NULL OR LOWER(s.academicLevel.program.code) = LOWER(:faculty)) " +
           "AND (:semester IS NULL OR s.academicLevel.levelNumber = :semester) " +
           "AND (:search IS NULL OR LOWER(s.user.name) LIKE LOWER(CONCAT('%', :search, '%')) OR LOWER(s.user.email) LIKE LOWER(CONCAT('%', :search, '%')))")
    Page<Student> findStudentsFiltered(
            @Param("tenantId") Long tenantId,
            @Param("programId") Long programId,
            @Param("levelId") Long levelId,
            @Param("faculty") String faculty,
            @Param("semester") Integer semester,
            @Param("search") String search,
            Pageable pageable
    );

    boolean existsByStudentIdAndUser_Institution_InstitutionId(
            long studentId,
            long tenantId
    );
}
