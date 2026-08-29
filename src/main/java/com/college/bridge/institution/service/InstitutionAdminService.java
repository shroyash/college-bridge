package com.college.bridge.institution.service;

import com.college.bridge.academic.repository.AcademicLevelRepository;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.common.tenant.TenantContext;
import com.college.bridge.institution.dto.InstitutionProfileResponse;
import com.college.bridge.institution.dto.UpdateInstitutionProfileRequest;
import com.college.bridge.institution.entity.Institution;
import com.college.bridge.institution.repository.InstitutionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.Principal;
import java.time.LocalDateTime;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class InstitutionAdminService {

    private final UserRepository userRepository;
    private final InstitutionRepository institutionRepository;
    private final AcademicLevelRepository academicLevelRepository;

    @Transactional(readOnly = true)
    public InstitutionProfileResponse getInstitutionProfile(Principal principal) {
        User adminUser = getAdminUser(principal);
        Institution inst = getInstitutionForUser(adminUser);

        Long instId = inst.getInstitutionId();
        long studentCount = instId != null ? userRepository.findByInstitution_InstitutionIdAndRole(instId, UserRole.STUDENT).size() : 0;
        long teacherCount = instId != null ? userRepository.findByInstitution_InstitutionIdAndRole(instId, UserRole.TEACHER).size() : 0;
        long classCount = instId != null ? academicLevelRepository.findByProgram_Institution_InstitutionId(instId).size() : 0;

        return mapToResponse(inst, studentCount, teacherCount, classCount);
    }

    public InstitutionProfileResponse updateInstitutionProfile(Principal principal, UpdateInstitutionProfileRequest request) {
        User adminUser = getAdminUser(principal);
        Institution inst = getInstitutionForUser(adminUser);

        if (request.getName() != null && !request.getName().isBlank()) {
            inst.setName(request.getName().trim());
        }
        if (request.getLocation() != null) {
            inst.setLocation(request.getLocation().trim());
        }
        if (request.getWebsite() != null) {
            inst.setWebsite(request.getWebsite().trim());
        }

        Institution saved = institutionRepository.save(inst);

        Long instId = saved.getInstitutionId();
        long studentCount = instId != null ? userRepository.findByInstitution_InstitutionIdAndRole(instId, UserRole.STUDENT).size() : 0;
        long teacherCount = instId != null ? userRepository.findByInstitution_InstitutionIdAndRole(instId, UserRole.TEACHER).size() : 0;
        long classCount = instId != null ? academicLevelRepository.findByProgram_Institution_InstitutionId(instId).size() : 0;

        return mapToResponse(saved, studentCount, teacherCount, classCount);
    }

    private User getAdminUser(Principal principal) {
        if (principal == null || principal.getName() == null) {
            throw new ResourceNotFoundException("Authentication principal is missing.");
        }
        String email = principal.getName();
        Long tenantId = TenantContext.get();
        if (tenantId != null) {
            Optional<User> tenantUser = userRepository.findByInstitution_InstitutionIdAndEmail(tenantId, email);
            if (tenantUser.isPresent()) {
                return tenantUser.get();
            }
        }
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with email: " + email));
    }

    private Institution getInstitutionForUser(User user) {
        if (user.getInstitution() != null) {
            return user.getInstitution();
        }
        Long tenantId = TenantContext.get();
        if (tenantId != null) {
            return institutionRepository.findById(tenantId)
                    .orElseThrow(() -> new ResourceNotFoundException("Institution not found for ID: " + tenantId));
        }
        return institutionRepository.findAll().stream().findFirst()
                .orElseThrow(() -> new ResourceNotFoundException("No institution found in system."));
    }

    private InstitutionProfileResponse mapToResponse(Institution inst, long studentCount, long teacherCount, long classCount) {
        return InstitutionProfileResponse.builder()
                .institutionId(inst.getInstitutionId())
                .name(inst.getName() != null ? inst.getName() : "")
                .code(inst.getCode() != null ? inst.getCode() : "")
                .status(inst.getStatus() != null ? inst.getStatus().name() : "ACTIVE")
                .location(inst.getLocation() != null ? inst.getLocation() : "")
                .website(inst.getWebsite() != null ? inst.getWebsite() : "")
                .createdAt(inst.getCreatedAt() != null ? inst.getCreatedAt() : LocalDateTime.now())
                .totalStudents(studentCount)
                .totalTeachers(teacherCount)
                .totalClasses(classCount)
                .build();
    }
}
