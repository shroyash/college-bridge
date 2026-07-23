package com.college.bridge.auth.repository;

import com.college.bridge.auth.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long>, JpaSpecificationExecutor<User> {
    
    Optional<User> findByEmail(String email);
    
    boolean existsByEmail(String email);

    long countByRoleAndStatus(com.college.bridge.auth.entity.UserRole role, com.college.bridge.auth.entity.UserStatus status);
}
