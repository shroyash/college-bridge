package com.college.bridge.holiday.application.port;

import com.college.bridge.institution.entity.InstitutionRegion;

import java.util.List;

/** Outbound port: which institutions take part. Implement on top of your institutions table. */
public interface InstitutionDirectory {

    /** Institutions that are approved/active and should receive holiday drafts. */
    List<InstitutionRef> eligibleInstitutions();

    String nameOf(Long institutionId);

    /** {@code region} may be null when the institution has not set one. */
    record InstitutionRef(Long id, String name, InstitutionRegion region) {}
}
