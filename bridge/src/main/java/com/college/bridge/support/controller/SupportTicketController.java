package com.college.bridge.support.controller;

import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.response.ApiResponse;
import com.college.bridge.support.dto.CreateSupportTicketRequest;
import com.college.bridge.support.dto.SupportTicketResponse;
import com.college.bridge.support.service.SupportTicketService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/support/tickets")
@RequiredArgsConstructor
public class SupportTicketController {

    private final SupportTicketService supportTicketService;

    @PostMapping
    public ResponseEntity<ApiResponse<SupportTicketResponse>> createTicket(
            @Valid @RequestBody CreateSupportTicketRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        SupportTicketResponse response = supportTicketService.createTicket(request, principal);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Support ticket created successfully.", response));
    }

    @GetMapping("/my")
    public ResponseEntity<ApiResponse<List<SupportTicketResponse>>> getMyTickets(
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        List<SupportTicketResponse> responses = supportTicketService.getMyTickets(principal);
        return ResponseEntity.ok(ApiResponse.success("My tickets retrieved successfully.", responses));
    }
}

