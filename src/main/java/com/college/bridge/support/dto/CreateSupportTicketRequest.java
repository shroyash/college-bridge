package com.college.bridge.support.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateSupportTicketRequest {

    @NotBlank(message = "Category is required.")
    @Size(max = 100, message = "Category must not exceed 100 characters.")
    private String category;

    @NotBlank(message = "Subject is required.")
    @Size(max = 255, message = "Subject must not exceed 255 characters.")
    private String subject;

    @NotBlank(message = "Description is required.")
    private String description;
}

