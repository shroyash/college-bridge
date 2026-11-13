package com.college.bridge.holiday.application.port;

/** Outbound port: push an approved notice to one institution's students and/or teachers. */
public interface AudienceBroadcaster {

    /** @throws BroadcastFailedException when delivery could not be completed */
    void broadcast(Broadcast broadcast);

    record Broadcast(Long institutionId, Long holidayId, String institutionName,
                     String title, String body, boolean students, boolean teachers) {}
}
