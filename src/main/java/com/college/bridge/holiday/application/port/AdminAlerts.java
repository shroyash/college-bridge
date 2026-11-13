package com.college.bridge.holiday.application.port;

import com.college.bridge.holiday.domain.PublicHoliday;

/** Outbound port: tell one institution's admins that something needs their attention. */
public interface AdminAlerts {

    void approvalRequested(Long institutionId, PublicHoliday holiday, boolean reminder);

    void publishingFailed(Long institutionId, PublicHoliday holiday);
}
