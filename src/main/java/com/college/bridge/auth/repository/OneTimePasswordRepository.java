package com.college.bridge.auth.repository;

import com.college.bridge.auth.entity.OneTimePassword;
import com.college.bridge.auth.entity.OtpType;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface OneTimePasswordRepository extends JpaRepository<OneTimePassword, Long> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    Optional<OneTimePassword> findFirstByEmailAndTypeAndVerifiedOrderByCreatedAtDesc(String email, OtpType type, boolean verified);

    void deleteByExpiryDateBefore(LocalDateTime expiryTime);
}
