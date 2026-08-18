package com.college.bridge.dashboard.service;

import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.repository.UserRepository;
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
    public long getTotalInstitutions() {
        return institutionRepository.count();
    }

    @Transactional(readOnly = true)
    public long getPendingInstitutions() {
        return institutionRepository.countByStatus(InstitutionStatus.PENDING);
    }

    @Transactional(readOnly = true)
    public long getActiveInstitutions() {
        return institutionRepository.countByStatus(InstitutionStatus.ACTIVE);
    }

    @Transactional(readOnly = true)
    public long getSuspendedInstitutions() {
        return institutionRepository.countByStatus(InstitutionStatus.SUSPENDED);
    }

    @Transactional(readOnly = true)
    public long getTotalUsers() {
        return userRepository.count();
    }

    @Transactional(readOnly = true)
    public long getTotalStudents() {
        return userRepository.countByRole(UserRole.STUDENT);
    }

    @Transactional(readOnly = true)
    public long getTotalTeachers() {
        return userRepository.countByRole(UserRole.TEACHER);
    }

    @Transactional(readOnly = true)
    public long getTotalAdmins() {
        return userRepository.countByRole(UserRole.ADMIN);
    }
}
