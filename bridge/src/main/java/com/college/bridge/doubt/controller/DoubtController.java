package com.college.bridge.doubt.controller;

import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.response.ApiResponse;
import com.college.bridge.doubt.dto.CreateDoubtRequest;
import com.college.bridge.doubt.dto.DoubtResponse;
import com.college.bridge.doubt.dto.DoubtSummaryResponse;
import com.college.bridge.doubt.service.DoubtService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/doubts")
@RequiredArgsConstructor
public class DoubtController {

    private final DoubtService doubtService;

    @PreAuthorize("hasRole('STUDENT')")
    @PostMapping
    public ResponseEntity<ApiResponse<DoubtResponse>> createDoubt(
            @Valid @RequestBody CreateDoubtRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        DoubtResponse response =
                doubtService.createDoubt(request, principal);

        return ResponseEntity.ok(
                ApiResponse.success(
                        "Doubt created successfully",
                        response
                )
        );
    }

    @GetMapping
    public ResponseEntity<ApiResponse<Page<DoubtResponse>>> getDoubts(
            @RequestParam(required = false) Long subjectId,
            @RequestParam(required = false) String search,
            Pageable pageable,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        Page<DoubtResponse> response =
                doubtService.getDoubts(
                        principal,
                        subjectId,
                        search,
                        pageable
                );

        return ResponseEntity.ok(
                ApiResponse.success(
                        "Doubts fetched successfully",
                        response
                )
        );
    }

    @GetMapping("/summary")
    public ResponseEntity<ApiResponse<DoubtSummaryResponse>> getDoubtSummary(
            @RequestParam(required = false) Long subjectId,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        DoubtSummaryResponse response =
                doubtService.getDoubtSummary(
                        subjectId,
                        principal
                );

        return ResponseEntity.ok(
                ApiResponse.success(
                        "Doubt summary fetched successfully",
                        response
                )
        );
    }

    @GetMapping("/{doubtId}")
    public ResponseEntity<ApiResponse<DoubtResponse>> getDoubt(
            @PathVariable Long doubtId,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        DoubtResponse response =
                doubtService.getDoubt(
                        doubtId,
                        principal
                );

        return ResponseEntity.ok(
                ApiResponse.success(
                        "Doubt fetched successfully",
                        response
                )
        );
    }

    @PreAuthorize("hasRole('STUDENT')")
    @PatchMapping("/{doubtId}/helpful")
    public ResponseEntity<ApiResponse<DoubtResponse>> markHelpful(
            @PathVariable Long doubtId,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        DoubtResponse response =
                doubtService.markHelpful(
                        doubtId,
                        principal
                );

        return ResponseEntity.ok(
                ApiResponse.success(
                        "Doubt helpful status updated",
                        response
                )
        );
    }
}