package com.college.bridge.doubt.controller;

import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.response.ApiResponse;
import com.college.bridge.doubt.service.DoubtAnswerService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/doubt-answers")
@RequiredArgsConstructor
public class DirectDoubtAnswerController {

    private final DoubtAnswerService doubtAnswerService;

    @PatchMapping("/{answerId}/verify")
    public ResponseEntity<ApiResponse<Void>> verifyAnswerDirect(
            @PathVariable Long answerId,
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        doubtAnswerService.verifyAnswerDirect(
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
