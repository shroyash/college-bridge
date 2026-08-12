package com.college.bridge.auth.repository;

import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.entity.UserStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long>, JpaSpecificationExecutor<User> {

    Optional<User> findByInstitution_InstitutionIdAndEmail(Long institutionId, String email);

    boolean existsByInstitution_InstitutionIdAndEmail(Long institutionId, String email);

    Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);

    long countByRoleAndStatus(UserRole role, UserStatus status);

    List<User> findByInstitution_InstitutionIdAndRole(Long institutionId, UserRole role);
}
