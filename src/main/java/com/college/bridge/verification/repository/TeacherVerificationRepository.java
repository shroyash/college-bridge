package com.college.bridge.verification.repository;

import com.college.bridge.auth.entity.User;
import com.college.bridge.verification.entity.TeacherVerificationRequest;
import com.college.bridge.verification.entity.VerificationStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TeacherVerificationRepository extends JpaRepository<TeacherVerificationRequest, Long> {

    Optional<TeacherVerificationRequest> findByUser(User user);

    boolean existsByUser(User user);

    List<TeacherVerificationRequest> findByStatus(VerificationStatus status);
}
