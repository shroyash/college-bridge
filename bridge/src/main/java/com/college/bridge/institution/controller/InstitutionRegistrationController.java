package com.college.bridge.institution.controller;

import com.college.bridge.common.response.ApiResponse;
import com.college.bridge.institution.dto.InstitutionRegistrationResponse;
import com.college.bridge.institution.dto.RegisterInstitutionRequest;
import com.college.bridge.institution.service.InstitutionRegistrationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class InstitutionRegistrationController {

    private final InstitutionRegistrationService registrationService;

    @PostMapping(value = "/register-institution", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<InstitutionRegistrationResponse>> registerInstitution(
            @Valid @RequestPart("request") RegisterInstitutionRequest request,
            @RequestPart("documents") List<MultipartFile> documents
    ) {
        InstitutionRegistrationResponse response = registrationService.registerInstitution(request, documents);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Submitted, awaiting approval.", response));
    }
}
