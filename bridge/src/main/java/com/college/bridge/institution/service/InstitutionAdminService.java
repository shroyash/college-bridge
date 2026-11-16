package com.college.bridge.institution.service;

import com.college.bridge.academic.repository.AcademicLevelRepository;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.common.tenant.TenantContext;
import com.college.bridge.institution.dto.InstitutionProfileResponse;
import com.college.bridge.institution.dto.UpdateInstitutionProfileRequest;
import com.college.bridge.institution.entity.Institution;
import com.college.bridge.institution.mapper.InstitutionMapper;
import com.college.bridge.institution.repository.InstitutionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional
public class InstitutionAdminService {

    private final UserRepository userRepository;
    private final InstitutionRepository institutionRepository;
    private final AcademicLevelRepository academicLevelRepository;
    private final InstitutionMapper institutionMapper;

    @Transactional(readOnly = true)
    public InstitutionProfileResponse getInstitutionProfile(UserPrincipal principal) {
        validatePrincipal(principal);
        Long institutionId = TenantContext.get();

        Institution institution = institutionRepository.findByInstitutionId(institutionId)
                .orElseThrow(() -> new ResourceNotFoundException("Institution not found with ID: " + institutionId));

        long studentCount = userRepository.countByInstitution_InstitutionIdAndRole(institutionId, UserRole.STUDENT);
        long teacherCount = userRepository.countByInstitution_InstitutionIdAndRole(institutionId, UserRole.TEACHER);
        long classCount = academicLevelRepository.countActiveByInstitutionId(institutionId);

        return institutionMapper.toProfileResponse(institution, studentCount, teacherCount, classCount);
    }

    public InstitutionProfileResponse updateInstitutionProfile(
            UserPrincipal principal,
            UpdateInstitutionProfileRequest request
    ) {
        validatePrincipal(principal);
        Long institutionId = TenantContext.get();

        Institution institution = institutionRepository.findByInstitutionId(institutionId)
                .orElseThrow(() -> new ResourceNotFoundException("Institution not found with ID: " + institutionId));

        if (request.getName() != null && !request.getName().isBlank()) {
            institution.setName(request.getName().trim());
        }

        if (request.getLocation() != null) {
            institution.setLocation(request.getLocation().trim());
        }

        if (request.getWebsite() != null) {
            institution.setWebsite(request.getWebsite().trim());
        }

        Institution savedInstitution = institutionRepository.save(institution);

        long studentCount = userRepository.countByInstitution_InstitutionIdAndRole(institutionId, UserRole.STUDENT);
        long teacherCount = userRepository.countByInstitution_InstitutionIdAndRole(institutionId, UserRole.TEACHER);
        long classCount = academicLevelRepository.countActiveByInstitutionId(institutionId);

        return institutionMapper.toProfileResponse(savedInstitution, studentCount, teacherCount, classCount);
    }

    private void validatePrincipal(UserPrincipal principal) {
        if (principal == null) {
            throw new ResourceNotFoundException("Authenticated user information is missing.");
        }

        if (principal.getInstitutionId() == null) {
            throw new ResourceNotFoundException("User is not associated with an institution.");
        }

        if (principal.getRole() != UserRole.ADMIN && principal.getRole() != UserRole.SUPER_ADMIN) {
            throw new ResourceNotFoundException("User is not authorized to manage an institution.");
        }

        Long tenantId = TenantContext.get();
        if (!principal.getInstitutionId().equals(tenantId)) {
            throw new ResourceNotFoundException("User does not belong to the current institution.");
        }
    }
}