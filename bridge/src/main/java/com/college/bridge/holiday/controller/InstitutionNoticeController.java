package com.college.bridge.holiday.controller;

import com.college.bridge.common.response.ApiResponse;
import com.college.bridge.holiday.application.notice.InstitutionNoticeView;
import com.college.bridge.holiday.application.notice.NoticeApprovalService;
import com.college.bridge.holiday.application.notice.NoticeApprovalService.ApproveCommand;
import com.college.bridge.holiday.controller.dto.NoticeApprovalRequest;
import com.college.bridge.holiday.application.port.Actor;
import com.college.bridge.holiday.application.port.CurrentUser;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/admin/holiday-notices")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class InstitutionNoticeController {

    private final NoticeApprovalService approvals;
    private final CurrentUser currentUser;

    @GetMapping("/pending")
    public ResponseEntity<ApiResponse<List<InstitutionNoticeView>>> pending() {
        List<InstitutionNoticeView> pendingNotices = approvals.pending(currentUser.actor().requireInstitutionId());
        return ResponseEntity.ok(ApiResponse.success("Pending holiday notices retrieved successfully.", pendingNotices));
    }

    @GetMapping("/{holidayId}")
    public ResponseEntity<ApiResponse<InstitutionNoticeView>> get(@PathVariable Long holidayId) {
        InstitutionNoticeView view = approvals.view(holidayId, currentUser.actor().requireInstitutionId());
        return ResponseEntity.ok(ApiResponse.success("Holiday notice retrieved successfully.", view));
    }

    /** First administrator of this institution wins; later calls get 409 Conflict. */
    @PostMapping("/{holidayId}/approve")
    public ResponseEntity<ApiResponse<InstitutionNoticeView>> approve(@PathVariable Long holidayId,
                                                                      @Valid @RequestBody NoticeApprovalRequest request) {
        Actor actor = currentUser.actor();
        InstitutionNoticeView view = approvals.approve(new ApproveCommand(holidayId, actor.requireInstitutionId(), actor.userId(),
                request.variant(), request.customTitle(), request.customBody(), request.audience()));
        return ResponseEntity.ok(ApiResponse.success("Holiday notice approved successfully.", view));
    }

    @PostMapping("/{holidayId}/reject")
    public ResponseEntity<ApiResponse<InstitutionNoticeView>> reject(@PathVariable Long holidayId) {
        Actor actor = currentUser.actor();
        InstitutionNoticeView view = approvals.reject(holidayId, actor.requireInstitutionId(), actor.userId());
        return ResponseEntity.ok(ApiResponse.success("Holiday notice rejected successfully.", view));
    }
}
