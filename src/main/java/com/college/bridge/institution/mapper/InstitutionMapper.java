package com.college.bridge.institution.mapper;

import com.college.bridge.institution.dto.InstitutionDocumentResponse;
import com.college.bridge.institution.dto.InstitutionProfileResponse;
import com.college.bridge.institution.dto.SuperAdminInstitutionResponse;
import com.college.bridge.institution.dto.SuperAdminPendingInstitutionResponse;
import com.college.bridge.institution.entity.Institution;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

@Mapper(componentModel = "spring")
public interface InstitutionMapper {

    @Mapping(target = "institutionId", source = "institution.institutionId")
    @Mapping(target = "name", expression = "java(institution.getName() != null ? institution.getName() : \"\")")
    @Mapping(target = "code", expression = "java(institution.getCode() != null ? institution.getCode() : \"\")")
    @Mapping(target = "status", expression = "java(institution.getStatus() != null ? institution.getStatus().name() : \"ACTIVE\")")
    @Mapping(target = "location", expression = "java(institution.getLocation() != null ? institution.getLocation() : \"\")")
    @Mapping(target = "website", expression = "java(institution.getWebsite() != null ? institution.getWebsite() : \"\")")
    @Mapping(target = "createdAt", source = "institution.createdAt")
    @Mapping(target = "totalStudents", source = "studentCount")
    @Mapping(target = "totalTeachers", source = "teacherCount")
    @Mapping(target = "totalClasses", source = "classCount")
    InstitutionProfileResponse toProfileResponse(
            Institution institution,
            long studentCount,
            long teacherCount,
            long classCount
    );

    @Mapping(target = "institutionId", source = "institution.institutionId")
    @Mapping(target = "institutionName", source = "institution.name")
    @Mapping(target = "code", source = "institution.code")
    @Mapping(target = "profileImage", source = "institution.profileImage")
    @Mapping(target = "location", source = "institution.location")
    @Mapping(target = "website", source = "institution.website")
    @Mapping(target = "contactEmail", expression = "java(institution.getSubmittedBy() != null ? institution.getSubmittedBy().getEmail() : null)")
    @Mapping(target = "contactPhone", ignore = true)
    @Mapping(target = "address", source = "institution.location")
    @Mapping(target = "status", source = "institution.status")
    @Mapping(target = "totalStudents", source = "totalStudents")
    @Mapping(target = "totalTeachers", source = "totalTeachers")
    @Mapping(target = "totalAdmins", source = "totalAdmins")
    @Mapping(target = "activeUsers", source = "activeUsers")
    @Mapping(target = "suspendedUsers", source = "suspendedUsers")
    @Mapping(target = "createdAt", source = "institution.createdAt")
    SuperAdminInstitutionResponse toSuperAdminResponse(
            Institution institution,
            long totalStudents,
            long totalTeachers,
            long totalAdmins,
            long activeUsers,
            long suspendedUsers
    );

    @Mapping(target = "institutionId", source = "institution.institutionId")
    @Mapping(target = "institutionName", source = "institution.name")
    @Mapping(target = "code", source = "institution.code")
    @Mapping(target = "profileImage", source = "institution.profileImage")
    @Mapping(target = "location", source = "institution.location")
    @Mapping(target = "website", source = "institution.website")
    @Mapping(target = "contactPerson", expression = "java(institution.getSubmittedBy() != null ? institution.getSubmittedBy().getName() : null)")
    @Mapping(target = "email", expression = "java(institution.getSubmittedBy() != null ? institution.getSubmittedBy().getEmail() : null)")
    @Mapping(target = "status", source = "institution.status")
    @Mapping(target = "totalStudents", source = "totalStudents")
    @Mapping(target = "totalTeachers", source = "teacherCount")
    @Mapping(target = "submittedAt", source = "institution.createdAt")
    @Mapping(target = "documents", source = "documents")
    SuperAdminPendingInstitutionResponse toPendingResponse(
            Institution institution,
            long totalStudents,
            long teacherCount,
            List<InstitutionDocumentResponse> documents
    );
}
