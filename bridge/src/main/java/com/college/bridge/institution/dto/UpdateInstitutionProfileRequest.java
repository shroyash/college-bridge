package com.college.bridge.institution.dto;

import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateInstitutionProfileRequest {

    @Size(max = 150, message = "Institution name cannot exceed 150 characters")
    private String name;

    @Size(max = 150, message = "Location cannot exceed 150 characters")
    private String location;

    @Size(max = 255, message = "Website cannot exceed 255 characters")
    private String website;
}
