package com.college.bridge.dashboard.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class SuperAdminDashboardResponse {

    private InstitutionStats institutions;
    private UserStats users;

    @Data
    @Builder
    public static class InstitutionStats {
        private long total;
        private long pending;
        private long active;
        private long suspended;
    }

    @Data
    @Builder
    public static class UserStats {
        private long total;
        private long students;
        private long teachers;
        private long admins;
    }
}