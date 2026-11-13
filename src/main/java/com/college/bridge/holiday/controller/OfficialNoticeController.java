package com.college.bridge.holiday.controller;

import com.college.bridge.common.response.ApiResponse;
import com.college.bridge.holiday.application.notice.OfficialNoticeQueryService;
import com.college.bridge.holiday.application.notice.OfficialNoticeView;
import com.college.bridge.holiday.application.notice.PagedResult;
import com.college.bridge.holiday.application.port.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Read side for everyone in an institution: the approved holiday notices that the push notification points to. */
@RestController
@RequestMapping("/api/holiday-notices")
@PreAuthorize("isAuthenticated()")
@RequiredArgsConstructor
public class OfficialNoticeController {

    private static final int MAX_PAGE_SIZE = 50;

    private final OfficialNoticeQueryService officialNotices;
    private final CurrentUser currentUser;

    @GetMapping("/official")
    public ResponseEntity<ApiResponse<PagedResult<OfficialNoticeView>>> official(@RequestParam(defaultValue = "0") int page,
                                                                                  @RequestParam(defaultValue = "20") int size) {
        int safePage = Math.max(0, page);
        int safeSize = Math.min(MAX_PAGE_SIZE, Math.max(1, size));
        PagedResult<OfficialNoticeView> result = officialNotices.list(currentUser.actor().requireInstitutionId(), PageRequest.of(safePage, safeSize));
        return ResponseEntity.ok(ApiResponse.success("Official holiday notices retrieved successfully.", result));
    }
}
