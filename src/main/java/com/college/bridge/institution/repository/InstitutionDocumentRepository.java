package com.college.bridge.institution.repository;

import com.college.bridge.institution.entity.InstitutionDocument;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface InstitutionDocumentRepository extends JpaRepository<InstitutionDocument, Long> {

    List<InstitutionDocument> findByInstitution_InstitutionId(Long institutionId);
}
