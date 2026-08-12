package com.college.bridge.institution.repository;

import com.college.bridge.institution.entity.Institution;
import com.college.bridge.institution.entity.InstitutionStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface InstitutionRepository extends JpaRepository<Institution, Long> {

    Optional<Institution> findByCode(String code);

    boolean existsByCode(String code);

    List<Institution> findByStatus(InstitutionStatus status);
}
