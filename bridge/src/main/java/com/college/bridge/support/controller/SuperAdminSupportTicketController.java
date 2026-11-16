package com.college.bridge.support.controller;

import com.college.bridge.common.response.ApiResponse;
import com.college.bridge.common.response.PageResponse;
import com.college.bridge.support.dto.SupportTicketResponse;
import com.college.bridge.support.dto.UpdateTicketStatusRequest;
import com.college.bridge.support.entity.TicketStatus;
import com.college.bridge.support.service.SupportTicketService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/super-admin/tickets")
@RequiredArgsConstructor
@PreAuthorize("hasRole('SUPER_ADMIN')")
public class SuperAdminSupportTicketController {

    private final SupportTicketService supportTicketService;

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<SupportTicketResponse>>> getAllTickets(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) TicketStatus status,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable
    ) {
        PageResponse<SupportTicketResponse> page =
                supportTicketService.getAllTickets(pageable, search, status);
        return ResponseEntity.ok(ApiResponse.success("Support tickets retrieved successfully.", page));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<SupportTicketResponse>> getTicketById(@PathVariable("id") Long id) {
        SupportTicketResponse response = supportTicketService.getTicketById(id);
        return ResponseEntity.ok(ApiResponse.success("Ticket details retrieved successfully.", response));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<SupportTicketResponse>> updateTicketStatus(
            @PathVariable("id") Long id,
            @Valid @RequestBody UpdateTicketStatusRequest request
    ) {
        SupportTicketResponse response = supportTicketService.updateStatus(id, request.getStatus());
        return ResponseEntity.ok(ApiResponse.success("Ticket status updated successfully.", response));
    }
}

