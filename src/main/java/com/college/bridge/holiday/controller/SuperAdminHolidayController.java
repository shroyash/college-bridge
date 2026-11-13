package com.college.bridge.holiday.controller;

import com.college.bridge.common.response.ApiResponse;
import com.college.bridge.holiday.application.calendar.HolidayCalendarSyncService;
import com.college.bridge.holiday.application.notice.HolidayDraftsView;
import com.college.bridge.holiday.application.notice.HolidayNoticeInspectionService;
import com.college.bridge.holiday.application.notice.NoticeDraftingService;
import com.college.bridge.holiday.application.port.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/** Platform-level operations. Super admins have no institution and cannot approve on a college's behalf. */
@RestController
@RequestMapping("/api/super-admin/holidays")
@PreAuthorize("hasRole('SUPER_ADMIN')")
@RequiredArgsConstructor
public class SuperAdminHolidayController {

    private final HolidayNoticeInspectionService inspection;
    private final NoticeDraftingService drafting;
    private final HolidayCalendarSyncService calendarSync;
    private final CurrentUser currentUser;

    @GetMapping("/{holidayId}")
    public ResponseEntity<ApiResponse<HolidayDraftsView>> inspect(@PathVariable Long holidayId) {
        HolidayDraftsView view = inspection.inspect(holidayId);
        return ResponseEntity.ok(ApiResponse.success("Holiday drafts inspected successfully.", view));
    }

    /** New AI drafts; refused with 409 once any institution is using the current text. */
    @PostMapping("/{holidayId}/regenerate")
    public ResponseEntity<ApiResponse<HolidayDraftsView>> regenerate(@PathVariable Long holidayId) {
        drafting.regenerate(holidayId, currentUser.actor().userId());
        HolidayDraftsView view = inspection.inspect(holidayId);
        return ResponseEntity.ok(ApiResponse.success("Holiday drafts regenerated successfully.", view));
    }

    /** Manual re-sync of the national calendar, e.g. right after the government announces a change. */
    @PostMapping("/sync")
    public ResponseEntity<ApiResponse<Map<String, Object>>> sync(@RequestParam int year) {
        Map<String, Object> result = Map.of("year", year, "holidays", calendarSync.sync(year));
        return ResponseEntity.ok(ApiResponse.success("Holiday calendar synced successfully.", result));
    }
}
