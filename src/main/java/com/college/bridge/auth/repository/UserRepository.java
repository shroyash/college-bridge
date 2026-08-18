package com.college.bridge.auth.repository;

import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.entity.UserStatus;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
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

    @org.springframework.data.jpa.repository.Query("SELECT u.institution.institutionId, u.role, COUNT(u) FROM User u WHERE u.institution.institutionId IS NOT NULL AND u.deleted = false GROUP BY u.institution.institutionId, u.role")
    List<Object[]> countUsersGroupByInstitutionAndRole();
}
