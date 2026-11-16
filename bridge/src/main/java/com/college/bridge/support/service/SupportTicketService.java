package com.college.bridge.support.service;

import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.response.PageResponse;
import com.college.bridge.support.dto.CreateSupportTicketRequest;
import com.college.bridge.support.dto.SupportTicketResponse;
import com.college.bridge.support.entity.TicketStatus;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface SupportTicketService {
    SupportTicketResponse createTicket(CreateSupportTicketRequest request, UserPrincipal principal);
    PageResponse<SupportTicketResponse> getAllTickets(Pageable pageable, String search, TicketStatus status);
    SupportTicketResponse getTicketById(Long ticketId);
    SupportTicketResponse updateStatus(Long ticketId, TicketStatus status);
    List<SupportTicketResponse> getMyTickets(UserPrincipal principal);
}

