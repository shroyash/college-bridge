package com.college.bridge.support.service;

import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.common.response.PageResponse;
import com.college.bridge.support.dto.CreateSupportTicketRequest;
import com.college.bridge.support.dto.SupportTicketResponse;
import com.college.bridge.support.entity.SupportTicket;
import com.college.bridge.support.entity.TicketStatus;
import com.college.bridge.support.repository.SupportTicketRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Random;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class SupportTicketServiceImpl implements SupportTicketService {

    private final SupportTicketRepository supportTicketRepository;
    private final UserRepository userRepository;
    private final Random random = new Random();

    @Override
    public SupportTicketResponse createTicket(CreateSupportTicketRequest request, UserPrincipal principal) {
        Long userId = principal != null ? principal.getUserId() : 1L;
        String userEmail = principal != null ? principal.getUsername() : "user@collegebridge.com";
        String userName = "User";
        String userRole = principal != null && principal.getRole() != null ? principal.getRole().name() : "STUDENT";
        Long institutionId = principal != null ? principal.getInstitutionId() : null;

        if (principal != null && principal.getUser() != null) {
            userName = principal.getUser().getName();
        } else {
            User user = userRepository.findById(userId).orElse(null);
            if (user != null) {
                userName = user.getName();
                userEmail = user.getEmail();
                userRole = user.getRole() != null ? user.getRole().name() : userRole;
                if (user.getInstitution() != null) {
                    institutionId = user.getInstitution().getInstitutionId();
                }
            }
        }

        String ticketNumber = generateUniqueTicketNumber();

        SupportTicket ticket = SupportTicket.builder()
                .ticketNumber(ticketNumber)
                .userId(userId)
                .userName(userName)
                .userEmail(userEmail)
                .userRole(userRole)
                .institutionId(institutionId)
                .category(request.getCategory())
                .subject(request.getSubject())
                .description(request.getDescription())
                .status(TicketStatus.OPEN)
                .build();

        SupportTicket saved = supportTicketRepository.save(ticket);
        log.info("Created support ticket: {} for user: {} ({})", ticketNumber, userName, userEmail);

        return SupportTicketResponse.from(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<SupportTicketResponse> getAllTickets(Pageable pageable, String search, TicketStatus status) {
        Page<SupportTicket> page = supportTicketRepository.findByFilter(search, status, pageable);
        return PageResponse.from(page.map(SupportTicketResponse::from));
    }

    @Override
    @Transactional(readOnly = true)
    public SupportTicketResponse getTicketById(Long ticketId) {
        SupportTicket ticket = supportTicketRepository.findById(ticketId)
                .orElseThrow(() -> new ResourceNotFoundException("Support ticket not found with id: " + ticketId));
        return SupportTicketResponse.from(ticket);
    }

    @Override
    public SupportTicketResponse updateStatus(Long ticketId, TicketStatus status) {
        SupportTicket ticket = supportTicketRepository.findById(ticketId)
                .orElseThrow(() -> new ResourceNotFoundException("Support ticket not found with id: " + ticketId));
        ticket.setStatus(status);
        SupportTicket updated = supportTicketRepository.save(ticket);
        log.info("Updated support ticket: {} status to: {}", ticket.getTicketNumber(), status);
        return SupportTicketResponse.from(updated);
    }

    @Override
    @Transactional(readOnly = true)
    public List<SupportTicketResponse> getMyTickets(UserPrincipal principal) {
        Long userId = principal != null ? principal.getUserId() : 1L;
        List<SupportTicket> tickets = supportTicketRepository.findByUserIdOrderByCreatedAtDesc(userId);
        return tickets.stream().map(SupportTicketResponse::from).toList();
    }

    private String generateUniqueTicketNumber() {
        for (int i = 0; i < 10; i++) {
            int randomNum = 1000 + random.nextInt(9000);
            String candidate = "TK-" + randomNum;
            if (supportTicketRepository.findByTicketNumber(candidate).isEmpty()) {
                return candidate;
            }
        }
        return "TK-" + System.currentTimeMillis() % 100000;
    }
}

