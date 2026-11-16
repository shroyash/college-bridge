package com.college.bridge.holiday.domain;

import com.college.bridge.institution.entity.InstitutionRegion;

/** Which institutions a holiday applies to. */
public enum HolidayScope {
    NATIONWIDE,
    HILLS,
    TERAI;

    /** An institution with no region configured is included: its admin decides. */
    public boolean appliesTo(InstitutionRegion region) {
        if (this == NATIONWIDE || region == null) {
            return true;
        }
        return (this == HILLS && region == InstitutionRegion.HILLS)
                || (this == TERAI && region == InstitutionRegion.TERAI);
    }
}
