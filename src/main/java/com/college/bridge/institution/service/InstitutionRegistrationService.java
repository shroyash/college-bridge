package com.college.bridge.institution.service;

import com.college.bridge.auth.entity.Admin;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.entity.UserStatus;
import com.college.bridge.auth.repository.AdminRepository;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.auth.service.FileStorageService;
import com.college.bridge.common.exception.BusinessRuleException;
import com.college.bridge.common.exception.DuplicateResourceException;
import com.college.bridge.institution.dto.InstitutionRegistrationResponse;
import com.college.bridge.institution.dto.RegisterInstitutionRequest;
import com.college.bridge.institution.entity.Institution;
import com.college.bridge.institution.entity.InstitutionDocument;
import com.college.bridge.institution.entity.InstitutionStatus;
import com.college.bridge.institution.repository.InstitutionDocumentRepository;
import com.college.bridge.institution.repository.InstitutionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class InstitutionRegistrationService {

    private final InstitutionRepository institutionRepository;
    private final UserRepository userRepository;
    private final AdminRepository adminRepository;
    private final InstitutionDocumentRepository institutionDocumentRepository;
    private final FileStorageService fileStorageService;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public InstitutionRegistrationResponse registerInstitution(RegisterInstitutionRequest request, List<MultipartFile> files) {
        if (files == null || files.isEmpty()) {
            throw new BusinessRuleException("At least one institution document upload is required.");
        }

        if (institutionRepository.existsByCode(request.getCode())) {
            throw new DuplicateResourceException("Institution code already exists: " + request.getCode());
        }

        // 1. Save Institution in PENDING state
        Institution institution = Institution.builder()
                .name(request.getName())
                .code(request.getCode())
                .status(InstitutionStatus.PENDING)
                .build();
        Institution savedInstitution = institutionRepository.save(institution);

        // Check if admin email already exists for this institution or globally
        if (userRepository.findByInstitution_InstitutionIdAndEmail(savedInstitution.getInstitutionId(), request.getAdminEmail()).isPresent()) {
            throw new DuplicateResourceException("Admin email already registered for institution: " + request.getAdminEmail());
        }

        // 2. Save Admin User in PENDING_VERIFICATION state
        User adminUser = User.builder()
                .institution(savedInstitution)
                .name(request.getAdminName())
                .email(request.getAdminEmail())
                .passwordHash(passwordEncoder.encode(request.getAdminPassword()))
                .role(UserRole.ADMIN)
                .status(UserStatus.PENDING_VERIFICATION)
                .build();
        User savedAdminUser = userRepository.save(adminUser);

        Admin adminProfile = Admin.builder()
                .user(savedAdminUser)
                .department("Institution Administrator")
                .build();
        adminRepository.save(adminProfile);

        // 3. Link submittedBy back to institution
        savedInstitution.setSubmittedBy(savedAdminUser);
        institutionRepository.save(savedInstitution);

        // 4. Save uploaded documents
        List<String> docTypes = request.getDocumentTypes();
        for (int i = 0; i < files.size(); i++) {
            MultipartFile file = files.get(i);
            String docType = (docTypes != null && i < docTypes.size()) ? docTypes.get(i) : "REGISTRATION_DOCUMENT";
            String docUrl = fileStorageService.storeDocument(file);

            InstitutionDocument document = InstitutionDocument.builder()
                    .institution(savedInstitution)
                    .documentUrl(docUrl)
                    .documentType(docType)
                    .build();
            institutionDocumentRepository.save(document);
        }

        log.info("Institution '{}' ({}) registered by admin '{}'. Status: PENDING.",
                savedInstitution.getName(), savedInstitution.getCode(), savedAdminUser.getEmail());

        return InstitutionRegistrationResponse.builder()
                .institutionId(savedInstitution.getInstitutionId())
                .name(savedInstitution.getName())
                .code(savedInstitution.getCode())
                .status(savedInstitution.getStatus())
                .message("Institution registration submitted successfully. Awaiting super admin approval.")
                .submittedAt(savedInstitution.getCreatedAt())
                .build();
    }
}
