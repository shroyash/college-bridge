package com.college.bridge.holiday.application.notice;

import com.college.bridge.holiday.config.NepalClock;
import com.college.bridge.holiday.domain.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.Comparator;
import java.util.List;
import java.util.Set;


@Service
@RequiredArgsConstructor
public class NoticeApprovalService {


    public record ApproveCommand(Long holidayId, Long institutionId, Long userId, NoticeVariant variant,
                                 String customTitle, String customBody, Set<NoticeAudience> audience) {}

    private final PublicHolidayRepository holidays;
    private final InstitutionNoticeRepository notices;
    private final NoticeDraftRepository drafts;
    private final AdminActionRepository actions;
    private final NepalClock clock;

    @Transactional(readOnly = true)
    public List<InstitutionNoticeView> pending(Long institutionId) {
        return notices.findAwaitingForInstitution(institutionId, clock.today()).stream()
                .map(notice -> view(notice.getHolidayId(), institutionId))
                .toList();
    }

    @Transactional(readOnly = true)
    public InstitutionNoticeView view(Long holidayId, Long institutionId) {
        PublicHoliday holiday = holiday(holidayId);
        InstitutionNotice notice = notice(holidayId, institutionId);
        List<DraftView> draftViews = drafts.findByHolidayId(holidayId).stream()
                .sorted(Comparator.comparing(NoticeDraft::getVariant))
                .map(draft -> new DraftView(draft.getVariant(), draft.getTitle(), draft.getBody(),
                        draft.getOrigin(), draft.getModel()))
                .toList();
        return new InstitutionNoticeView(holiday.getId(), holiday.getName(), holiday.getDateAd(), holiday.getDateBs(),
                notice.getStatus(), notice.getApprovedVariant(), notice.getFinalTitle(), notice.getFinalBody(),
                draftViews);
    }

    /** Approving makes the notice official immediately; the push notification is delivered separately. */
    @Transactional
    public InstitutionNoticeView approve(ApproveCommand command) {
        PublicHoliday holiday = holiday(command.holidayId());
        if (holiday.getDateAd().isBefore(clock.today())) {
            throw new NoticeConflictException("This holiday date has already passed");
        }
        notice(command.holidayId(), command.institutionId()); // proves this institution has a notice for it
        NoticeDraft draft = drafts.findByHolidayIdAndVariant(command.holidayId(), command.variant())
                .orElseThrow(() -> new NoticeNotFoundException("Draft not ready yet"));

        String title = finalText(command.customTitle(), draft.getTitle(), NoticeDraft.TITLE_MAX_LENGTH, "title");
        String body = finalText(command.customBody(), draft.getBody(), NoticeDraft.BODY_MAX_LENGTH, "body");
        Set<NoticeAudience> audience = command.audience();

        int changed = notices.approveIfAwaiting(command.holidayId(), command.institutionId(), command.variant(),
                title, body, audience.contains(NoticeAudience.STUDENTS), audience.contains(NoticeAudience.TEACHERS),
                command.userId(), clock.instantNow());
        if (changed == 0) {
            throw new NoticeConflictException(
                    "This notice was already decided (possibly by another administrator). Please refresh.");
        }
        actions.save(AdminAction.of(command.holidayId(), command.institutionId(), command.userId(),
                AdminActionType.APPROVED_NOTICE));
        return view(command.holidayId(), command.institutionId());
    }

    /** Explicitly declines to announce anything for this holiday. */
    @Transactional
    public InstitutionNoticeView reject(Long holidayId, Long institutionId, Long userId) {
        notice(holidayId, institutionId);
        int changed = notices.rejectIfAwaiting(holidayId, institutionId, userId, clock.instantNow());
        if (changed == 0) {
            throw new NoticeConflictException(
                    "This notice was already decided (possibly by another administrator). Please refresh.");
        }
        actions.save(AdminAction.of(holidayId, institutionId, userId, AdminActionType.REJECTED_NOTICE));
        return view(holidayId, institutionId);
    }

    /** Admin text (if any) replaces the draft text; it is cleaned and must not end up empty or too long. */
    private static String finalText(String custom, String draftText, int maxLength, String field) {
        String text = NoticeTextSanitizer.clean(custom == null || custom.isBlank() ? draftText : custom);
        if (text.isEmpty()) {
            throw new NoticeInvalidException("The notice " + field + " is empty after cleaning");
        }
        if (text.length() > maxLength) {
            throw new NoticeInvalidException("The notice " + field + " is longer than " + maxLength + " characters");
        }
        return text;
    }

    private PublicHoliday holiday(Long holidayId) {
        return holidays.findById(holidayId)
                .orElseThrow(() -> new NoticeNotFoundException("Holiday not found: " + holidayId));
    }

    /** Same message whether the holiday does not exist or belongs to nobody here: no information leaks across tenants. */
    private InstitutionNotice notice(Long holidayId, Long institutionId) {
        return notices.findByHolidayIdAndInstitutionId(holidayId, institutionId)
                .orElseThrow(() -> new NoticeNotFoundException("No notice for this holiday at your institution"));
    }
}
