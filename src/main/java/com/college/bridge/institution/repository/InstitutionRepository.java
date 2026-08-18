package com.college.bridge.institution.repository;

import com.college.bridge.institution.entity.Institution;
import com.college.bridge.institution.entity.InstitutionStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface InstitutionRepository extends JpaRepository<Institution, Long>, JpaSpecificationExecutor<Institution> {

    Optional<Institution> findByCode(String code);

    boolean existsByCode(String code);

    List<Institution> findByStatus(InstitutionStatus status);

    long countByStatus(InstitutionStatus status);
}
