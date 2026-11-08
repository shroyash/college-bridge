# Holiday Notices Feature — Design & Product Specification

> **Version**: 1.0  
> **Date**: 2026-11-08  
> **Target Package**: `lib/features/holiday_notices/`  
> **Design Alignment**: Built specifically for `bridge_mobile` using `AppColors`, `AppTypography`, `PrimaryButton`, and clean Riverpod state management.

---

## 1. Users & Jobs-to-be-Done

1. **College Administrator (ADMIN)**:
   * *"Tomorrow is an official national or regional holiday. The system has automatically prepared draft notices. I want to see the options ('College Closed' vs 'College Open'), tweak the wording or choose the recipient audience if necessary, and approve it in one tap so my campus is officially notified without delay."*
   * *"If our college has scheduled special exams or lab sessions, I can reject the closure notice or customize the operational hours."*
2. **Student & Teacher**:
   * *"I want to know with certainty whether classes and college operations are open or closed for an upcoming holiday, backed by an official, signed notice from my college administration."*

---

## 2. User Flows

### Flow 1: Admin Receives Push & Approves Notice
1. Admin device receives push notification (`type = "HOLIDAY_DRAFT_READY"` or `"HOLIDAY_APPROVAL"`).
2. Tapping the push navigates to the Notice Review screen (`/admin/holiday-notices/:id` or `/admin/holiday-notices/pending`).
3. Screen displays holiday date header in Nepal Time (e.g. *"Tomorrow · Thursday, 17 Oct 2024 (2081-07-01 BS)"*).
4. Admin reviews two draft cards:
   * **CLOSED Proposal**: e.g., *"Dashain Vacation: Academic Operations Closed"*
   * **OPEN Proposal**: e.g., *"Notice: Regular Lectures & Exams Proceed as Scheduled"*
5. Admin taps the **CLOSED** card. Card highlights with primary indigo border and checkmark.
6. An accordion section expands: "Customize Notice (Optional)", pre-filled with the selected draft's title and body.
7. Admin adjusts title or adds a specific note (live UTF-16 character counters: title `max 255`, body `max 2000`).
8. Admin reviews Audience Filter Chips: `[✓] Students` (default on), `[✓] Teachers` (default on). At least one must remain selected.
9. Admin clicks **"Approve and Publish"** (`PrimaryButton`).
10. A quick confirmation dialog appears: *"This publishes the notice to your campus now. Continue?"*
11. Admin confirms. Button transitions to loading state (`isLoading = true`). Request POST `/api/admin/holiday-notices/:id/approve` executes.
12. On HTTP 200 success: screen transitions in place to the **Decided State (A3)** with a green floating snackbar: *"Notice approved. Campus notifications are on their way."*

### Flow 2: Admin Decides Not to Announce (Reject)
1. In review screen, admin clicks secondary button *"Don't announce"*.
2. Modal dialog warns: *"Are you sure you do not want to publish any announcement for this holiday? Students and teachers will not receive an official notice."*
3. On confirmation, POST `/api/admin/holiday-notices/:id/reject` is called.
4. Screen transitions to Decided State with grey status banner: *"You chose not to announce this holiday."*

### Flow 3: Concurrent Approval Race Condition (HTTP 409)
1. Admin A and Admin B open the review screen simultaneously.
2. Admin A clicks approve first; notice transitions to `APPROVED`.
3. Admin B clicks approve seconds later. Backend responds with HTTP 409 Conflict (`application/problem+json`).
4. App catches `ConflictFailure` and presents an informative dialog:
   * Title: *"Notice Already Decided"*
   * Body: *"Another administrator has already approved or rejected this notice. Reloading the latest official state."*
5. On dialog dismiss (or automatically), screen re-fetches latest state from server and displays the read-only Decided View (A3) reflecting Admin A's submission.

### Flow 4: Expired or Past Notice
1. Admin opens the review screen for a holiday whose calendar date has already passed.
2. Notice is in `EXPIRED` status or date is in the past.
3. Review screen renders read-only banner: *"The date for this holiday has passed without a decision."*
4. All editing and approval buttons are disabled.

### Flow 5: Student / Teacher Reads Official Holiday Notice
1. Student/Teacher receives push notification (`type = "HOLIDAY_NOTICE"`).
2. App opens directly to Notice Detail screen (`/holiday-notices/:id` or from the Official Notices list `/holiday-notices/official`).
3. Screen displays official college banner, verified badge, holiday title, bilingual announcement body, and timestamp in Nepal Time.

---

## 3. Screen Wireframes & UI Specifications

### Screen A1: Admin Dashboard Notice Banner & Pending List
```
┌────────────────────────────────────────────────────────┐
│ [←] Pending Holiday Notices              [↻ Refresh]   │
├────────────────────────────────────────────────────────┤
│ ┌────────────────────────────────────────────────────┐ │
│ │ ⚡ ACTION REQUIRED                         Tomorrow │ │
│ │ Dashain - Vijaya Dashami (2081-07-01 BS)           │ │
│ │ Awaiting your decision: College Closed vs Open      │ │
│ │ [ Review & Decide → ]                              │ │
│ └────────────────────────────────────────────────────┘ │
│                                                        │
│ [Empty State when 0 pending]:                          │
│        (🏖️ Calendar icon)                              │
│   "No holiday notices need your decision."             │
│   All upcoming holidays have been addressed.           │
└────────────────────────────────────────────────────────┘
```

### Screen A2: Notice Review & Approval
```
┌────────────────────────────────────────────────────────┐
│ [←] Review Holiday Notice                              │
├────────────────────────────────────────────────────────┤
│ 📅 Tomorrow · Thursday, 17 Oct 2024 (2081-07-01 BS)   │
│ Dashain - Vijaya Dashami (Nationwide Scope)           │
│                                                        │
│ ℹ️ The app generated two drafts. Pick the one that     │
│    matches your college. Nothing is sent until you     │
│    approve.                                            │
│                                                        │
│ ┌────────────────────────────────────────────────────┐ │
│ │ [✓] OPTION A: COLLEGE CLOSED        [AI Draft 🤖]  │ │
│ │ "Official Dashain Holiday Notice"                  │ │
│ │ The college will remain closed for lectures...     │ │
│ └────────────────────────────────────────────────────┘ │
│                                                        │
│ ┌────────────────────────────────────────────────────┐ │
│ │ [ ] OPTION B: COLLEGE OPEN          [Standard 📋]  │ │
│ │ "Notice: Academic Operations as Usual"             │ │
│ │ Scheduled lectures and laboratory exams proceed... │ │
│ └────────────────────────────────────────────────────┘ │
│                                                        │
│ ✏️ EDIT WORDING (Optional)                 [Reset ↺]   │
│ ┌────────────────────────────────────────────────────┐ │
│ │ Title: Official Dashain Holiday Notice     31/255  │ │
│ ├────────────────────────────────────────────────────┤ │
│ │ Body:                                              │ │
│ │ Respected Faculty & Students,                      │ │
│ │ College operations will remain suspended...        │ │
│ │                                           142/2000 │ │
│ └────────────────────────────────────────────────────┘ │
│                                                        │
│ 👥 SEND TO AUDIENCE:                                   │
│   [✓ Students]   [✓ Teachers]                          │
│                                                        │
│ ┌────────────────────────────────────────────────────┐ │
│ │ [PrimaryButton: Approve and Publish]               │ │
│ └────────────────────────────────────────────────────┘ │
│                [ Don't announce (Reject) ]             │
└────────────────────────────────────────────────────────┘
```

### Screen A3: Decided State (Read-Only)
```
┌────────────────────────────────────────────────────────┐
│ [←] Holiday Notice Detail                              │
├────────────────────────────────────────────────────────┤
│ ┌────────────────────────────────────────────────────┐ │
│ │ 🟢 APPROVED AND PUBLISHED                          │ │
│ │ Published on 16 Oct 2024, 01:15 PM NPT             │ │
│ └────────────────────────────────────────────────────┘ │
│                                                        │
│ Dashain - Vijaya Dashami                               │
│ Thursday, 17 Oct 2024 · 2081-07-01 BS                  │
│                                                        │
│ Chosen Decision: COLLEGE CLOSED                        │
│                                                        │
│ Official Announcement:                                 │
│ ┌────────────────────────────────────────────────────┐ │
│ │ Official Dashain Holiday Notice                    │ │
│ │                                                    │ │
│ │ Respected Faculty & Students,                      │ │
│ │ All lectures and administrative sessions remain... │ │
│ └────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────┘
```

### Screen B1: Official Holiday Notices (Students / Teachers / Public)
```
┌────────────────────────────────────────────────────────┐
│ [←] Campus Holiday Notices                [↻ Refresh]  │
├────────────────────────────────────────────────────────┤
│ ┌────────────────────────────────────────────────────┐ │
│ │ Dashain - Vijaya Dashami               17 Oct 2024 │ │
│ │ [CLOSED] Official Dashain Holiday Notice           │ │
│ │ Campus will remain closed for students and faculty.│ │
│ │ Published: 16 Oct 2024 (Nepal Time)                │ │
│ └────────────────────────────────────────────────────┘ │
│ ┌────────────────────────────────────────────────────┐ │
│ │ Constitution Day                       19 Sep 2024 │ │
│ │ [CLOSED] Constitution Day Observance               │ │
│ │ Classes suspended. Administrative office open.     │ │
│ └────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────┘
```

---

## 4. State Inventory per Screen

| Screen | State | Visual Representation |
|--------|-------|-----------------------|
| **A1. Pending Notices** | `loading` | Centered `AppLoading` or shimmering list skeleton |
| | `empty` | `AppEmptyState` with calendar icon: *"No holiday notices need your decision."* |
| | `content` | Actionable card for today/tomorrow's holiday with badge |
| | `error` | `AppErrorState` with retry button |
| **A2. Review & Approve** | `loading` | Full-screen `AppLoading` while loading notice & drafts |
| | `content` | Two selectable cards, expandable edit form, audience filter chips |
| | `submitting` | `PrimaryButton.isLoading = true`, all fields disabled to prevent multi-tap |
| | `conflict (409)` | Modal Alert: *"Another administrator already decided this notice"*, reloads A3 |
| | `forbidden (403)` | `AppErrorState`: *"You do not have administrative access for this institution."* |
| | `notFound (404)` | `AppErrorState`: *"This holiday notice is no longer available."* |
| | `expired` | Read-only banner: *"This holiday notice has expired."* |
| **A3. Decided View** | `APPROVED/PUBLISHING` | Blue banner: *"Approved. Sending campus notifications..."* |
| | `PUBLISHED` | Green banner: *"Approved and sent to campus."* |
| | `FAILED` | Amber banner: *"Official and visible in app, but push delivery encountered an issue."* |
| | `REJECTED` | Slate banner: *"You chose not to announce this holiday."* |
| | `EXPIRED` | Grey banner: *"The date passed without a decision."* |
| **B1. Official Notices** | `loading` | `AppLoading` |
| | `empty` | `AppEmptyState`: *"No holiday notices yet."* |
| | `content` | Infinite scroll paged list with pull-to-refresh |
| | `error` | `AppErrorState` with retry button |

---

## 5. Copy & Localization Table

| Key | User-Visible English Copy | Context |
|-----|---------------------------|---------|
| `pending_title` | "Pending Holiday Notices" | App bar title |
| `pending_banner_title` | "Action Required: Holiday Notice" | Admin home dashboard |
| `pending_empty_title` | "No holiday notices need your decision" | Empty state title |
| `pending_empty_desc` | "All upcoming national and regional holidays have been reviewed." | Empty state subtitle |
| `review_title` | "Review Holiday Notice" | Screen title |
| `review_helper` | "The app proposes two notices. Pick the one that matches your college. Nothing is sent until you approve." | Helper callout |
| `variant_closed` | "College Closed" | Card A title |
| `variant_open` | "College Open" | Card B title |
| `badge_ai` | "AI Draft" | Variant chip |
| `badge_template` | "Standard Template" | Variant chip |
| `edit_section_title` | "Customize Announcement" | Collapsible section |
| `reset_button` | "Reset to proposal" | Action button |
| `field_title` | "Notice Title" | Text field label |
| `field_body` | "Notice Body" | Text field label |
| `audience_label` | "Send notification to:" | Chip group label |
| `audience_students` | "Students" | Filter chip |
| `audience_teachers` | "Teachers" | Filter chip |
| `btn_approve` | "Approve and Publish" | Primary button |
| `btn_reject` | "Don't announce" | Secondary text button |
| `confirm_approve_title` | "Publish Announcement?" | Dialog title |
| `confirm_approve_msg` | "This will publish the notice and notify selected campus recipients immediately." | Dialog body |
| `confirm_reject_title` | "Skip Announcement?" | Dialog title |
| `confirm_reject_msg` | "Are you sure you do not want to announce this holiday? No notifications will be dispatched." | Dialog body |
| `conflict_dialog_title` | "Notice Already Decided" | 409 Dialog |
| `conflict_dialog_msg` | "Another administrator has already decided this notice. Loading latest state." | 409 Dialog |
| `status_approved` | "Approved. Dispatching notifications." | Status banner |
| `status_published` | "Approved and sent to campus." | Status banner |
| `status_failed` | "Notice is official, but push delivery failed." | Status banner |
| `status_rejected` | "You chose not to announce this holiday." | Status banner |
| `status_expired` | "The holiday date passed without a decision." | Status banner |
| `official_list_title` | "Campus Holiday Notices" | Public list title |

---

## 6. Open Questions & Assumptions

1. **Question**: Does `bridge_mobile` feature a dedicated Super Admin shell?  
   * **Verification**: Yes, `SuperAdminShell` exists at `/super-admin`. However, Prompt 2 states: *"Super admin: Lowest priority; follow the same patterns"*. The core focus is College Admin (A1, A2, A3) and Student/Teacher/Public (B1, B2).
2. **Question**: Are audiences sent as separate boolean flags or an array?  
   * **Resolution**: The verified API contract implemented in Spring Boot accepts:
     ```json
     {
       "variant": "CLOSED",
       "customTitle": "...",
       "customBody": "...",
       "notifyStudents": true,
       "notifyTeachers": true
     }
     ```
     The DTO and repository will supply `notifyStudents` and `notifyTeachers` matching the verified backend `ApproveNoticeCommand.java`.
3. **Question**: How should Nepal Time be computed when device timezone is set abroad?  
   * **Resolution**: Dedicated `NepalTimeHelper` converts `DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 45))` to derive today's date in Kathmandu without timezone package dependencies or DST discrepancies.
