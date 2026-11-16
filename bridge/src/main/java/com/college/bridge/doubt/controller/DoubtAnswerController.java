package com.college.bridge.doubt.controller;

import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.response.ApiResponse;
import com.college.bridge.doubt.dto.CreateDoubtAnswerRequest;
import com.college.bridge.doubt.dto.DoubtAnswerResponse;
import com.college.bridge.doubt.service.DoubtAnswerService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/doubts/{doubtId}/answers")
@RequiredArgsConstructor
public class DoubtAnswerController {

    private final DoubtAnswerService doubtAnswerService;

    @PreAuthorize("hasAnyRole('STUDENT', 'TEACHER')")
    @PostMapping
    public ResponseEntity<ApiResponse<DoubtAnswerResponse>> answerDoubt(
            @PathVariable Long doubtId,
            @Valid @RequestBody CreateDoubtAnswerRequest request,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        DoubtAnswerResponse response =
                doubtAnswerService.answerDoubt(
                        doubtId,
                        request,
                        principal
                );

        return ResponseEntity.ok(
                ApiResponse.success(
                        "Answer submitted successfully",
                        response
                )
        );
    }

    @GetMapping
    public ResponseEntity<ApiResponse<Page<DoubtAnswerResponse>>> getAnswers(
            @PathVariable Long doubtId,
            @RequestParam(required = false) Boolean verified,
            Pageable pageable,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        Page<DoubtAnswerResponse> response =
                doubtAnswerService.getAnswers(
                        doubtId,
                        verified,
                        pageable,
                        principal
                );

        return ResponseEntity.ok(
                ApiResponse.success(
                        "Answers fetched successfully",
                        response
                )
        );
    }

    @PatchMapping("/{answerId}/verify")
    public ResponseEntity<ApiResponse<Void>> verifyAnswer(
            @PathVariable Long doubtId,
            @PathVariable Long answerId,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        doubtAnswerService.verifyAnswer(
                doubtId,
                answerId,
                principal
        );

        return ResponseEntity.ok(
                ApiResponse.success(
                        "Answer verified successfully"
                )
        );
    }
}