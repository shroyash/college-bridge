package com.college.bridge.holiday.application.port;

/** Outbound port: who is calling. Implement on top of your TenantContext / UserPrincipal. */
public interface CurrentUser {

    Actor actor();
}
