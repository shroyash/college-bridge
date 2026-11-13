package com.college.bridge.holiday.application.port;

import java.util.Collection;
import java.util.List;

/** Outbound port: the phones of ONE institution's admins. Implement on top of your users table. */
public interface AdminDirectory {

    List<AdminDevice> activeDevices(Long institutionId);

    /** Forget device tokens that the push service reported as no longer valid. */
    void forget(Collection<String> deviceTokens);

    record AdminDevice(Long adminId, String token) {}
}
