package com.college.bridge.institution.repository;

import com.college.bridge.institution.entity.Institution;
import com.college.bridge.institution.entity.InstitutionStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface InstitutionRepository extends JpaRepository<Institution, Long> {

    Optional<Institution> findByCode(String code);

    boolean existsByCode(String code);

    List<Institution> findByStatus(InstitutionStatus status);

    long countByStatus(InstitutionStatus status);

    Optional<Institution> findByInstitutionId(long id);

    @Query("""
        SELECT i FROM Institution i
        WHERE i.status = :status
        AND (LOWER(i.name) LIKE LOWER(CONCAT('%', :search, '%'))
             OR LOWER(i.code) LIKE LOWER(CONCAT('%', :search, '%')))
        """)
    List<Institution> findByStatusAndSearch(
            @Param("status") InstitutionStatus status,
            @Param("search") String search
    );

    @Query("""
        SELECT i FROM Institution i
        WHERE (:status IS NULL OR i.status = :status)
        AND (:search IS NULL
             OR LOWER(i.name) LIKE LOWER(CONCAT('%', :search, '%'))
             OR LOWER(i.code) LIKE LOWER(CONCAT('%', :search, '%')))
        """)
    Page<Institution> searchAll(
            @Param("status") InstitutionStatus status,
            @Param("search") String search,
            Pageable pageable
    );
}