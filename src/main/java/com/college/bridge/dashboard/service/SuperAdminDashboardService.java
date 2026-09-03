package com.college.bridge.dashboard.service;

import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.dashboard.dto.SuperAdminDashboardResponse;
import com.college.bridge.institution.entity.InstitutionStatus;
import com.college.bridge.institution.repository.InstitutionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class SuperAdminDashboardService {

    private final InstitutionRepository institutionRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public SuperAdminDashboardResponse getDashboard() {

        SuperAdminDashboardResponse.InstitutionStats institutionStats =
                SuperAdminDashboardResponse.InstitutionStats.builder()
                        .total(institutionRepository.count())
                        .pending(institutionRepository.countByStatus(InstitutionStatus.PENDING))
                        .active(institutionRepository.countByStatus(InstitutionStatus.ACTIVE))
                        .suspended(institutionRepository.countByStatus(InstitutionStatus.SUSPENDED))
                        .build();

        SuperAdminDashboardResponse.UserStats userStats =
                SuperAdminDashboardResponse.UserStats.builder()
                        .total(userRepository.count())
                        .students(userRepository.countByRole(UserRole.STUDENT))
                        .teachers(userRepository.countByRole(UserRole.TEACHER))
                        .admins(userRepository.countByRole(UserRole.ADMIN))
                        .build();

        return SuperAdminDashboardResponse.builder()
                .institutions(institutionStats)
                .users(userStats)
                .build();
    }
}