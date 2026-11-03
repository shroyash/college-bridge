package com.college.bridge.support.dto;

import com.college.bridge.support.entity.SupportTicket;
import com.college.bridge.support.entity.TicketStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SupportTicketResponse {

    private Long ticketId;
    private String ticketNumber;
    private Long userId;
    private String userName;
    private String userEmail;
    private String userRole;
    private Long institutionId;
    private String category;
    private String subject;
    private String description;
    private TicketStatus status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static SupportTicketResponse from(SupportTicket ticket) {
        return SupportTicketResponse.builder()
                .ticketId(ticket.getTicketId())
                .ticketNumber(ticket.getTicketNumber())
                .userId(ticket.getUserId())
                .userName(ticket.getUserName())
                .userEmail(ticket.getUserEmail())
                .userRole(ticket.getUserRole())
                .institutionId(ticket.getInstitutionId())
                .category(ticket.getCategory())
                .subject(ticket.getSubject())
                .description(ticket.getDescription())
                .status(ticket.getStatus())
                .createdAt(ticket.getCreatedAt())
                .updatedAt(ticket.getUpdatedAt())
                .build();
    }
}

