package com.college.bridge.auth.repository;

import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.entity.UserStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long>, JpaSpecificationExecutor<User> {

    @EntityGraph(attributePaths = {"institution"})
    Optional<User> findByInstitution_InstitutionIdAndEmail(Long institutionId, String email);

    boolean existsByInstitution_InstitutionIdAndEmail(Long institutionId, String email);

    @EntityGraph(attributePaths = {"institution"})
    Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);

    long countByRoleAndStatus(UserRole role, UserStatus status);

    long countByRole(UserRole role);

    List<User> findByInstitution_InstitutionIdAndRole(Long institutionId, UserRole role);

    @Query("""
        SELECT u.institution.institutionId, u.role, COUNT(u)
        FROM User u
        WHERE u.institution.institutionId IN :institutionIds
          AND u.deleted = false
        GROUP BY u.institution.institutionId, u.role
    """)
    List<Object[]> countUsersGroupByInstitutionAndRole(
            @Param("institutionIds") List<Long> institutionIds
    );

    @Query("""
        SELECT u.institution.institutionId, u.status, COUNT(u)
        FROM User u
        WHERE u.institution.institutionId IN :institutionIds
        AND u.deleted = false
        GROUP BY u.institution.institutionId, u.status
    """)
    List<Object[]> countUsersGroupByInstitutionAndStatus(@Param("institutionIds") List<Long> institutionIds);

    long countByInstitution_InstitutionIdAndRole(
            Long institutionId,
            UserRole role
    );

    // ---- Admin user list / search / filter, tenant-scoped ----

    @EntityGraph(attributePaths = {"institution"})
    Page<User> findByInstitution_InstitutionIdAndDeletedFalse(Long institutionId, Pageable pageable);

    @EntityGraph(attributePaths = {"institution"})
    Page<User> findByInstitution_InstitutionIdAndRoleAndStatusAndDeletedFalse(
            Long institutionId, UserRole role, UserStatus status, Pageable pageable);

    // SUPER_ADMIN only — deliberately no institution filter
    @EntityGraph(attributePaths = {"institution"})
    Page<User> findByRoleAndStatusAndDeletedFalse(UserRole role, UserStatus status, Pageable pageable);

    @Query("""
        SELECT u FROM User u
        WHERE u.institution.institutionId = :institutionId
          AND u.deleted = false
          AND (LOWER(u.email) LIKE LOWER(CONCAT('%', :query, '%'))
               OR LOWER(u.name) LIKE LOWER(CONCAT('%', :query, '%')))
    """)
    Page<User> searchWithinInstitution(@Param("institutionId") Long institutionId,
                                       @Param("query") String query,
                                       Pageable pageable);

    // SUPER_ADMIN only — deliberately no institution filter
    @Query("""
        SELECT u FROM User u
        WHERE u.deleted = false
          AND (LOWER(u.email) LIKE LOWER(CONCAT('%', :query, '%'))
               OR LOWER(u.name) LIKE LOWER(CONCAT('%', :query, '%')))
    """)
    Page<User> searchAllInstitutions(@Param("query") String query, Pageable pageable);

    @Query("SELECT u FROM User u WHERE u.userId = :userId AND u.institution.institutionId = :institutionId AND u.deleted = false")
    Optional<User> findByIdAndInstitutionId(
            @Param("userId") Long userId,
            @Param("institutionId") Long institutionId
    );
}