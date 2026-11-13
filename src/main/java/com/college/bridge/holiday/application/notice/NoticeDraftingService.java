package com.college.bridge.holiday.application.notice;

import com.college.bridge.holiday.application.port.AdminAlerts;
import com.college.bridge.holiday.application.port.NoticeWriter.WrittenNotice;
import com.college.bridge.holiday.application.port.NoticeWriter.WrittenNotices;
import com.college.bridge.holiday.domain.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.LocalDate;
import java.util.List;

/**
 * Use case: write the two SHARED drafts of a holiday once, then offer them to every eligible institution.
 * Every step is idempotent, so a cron retry or a second server never creates duplicates.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class NoticeDraftingService {

    /** Statuses in which an institution is already using the draft text. */
    private static final List<NoticeStatus> TEXT_IN_USE = List.of(
            NoticeStatus.APPROVED, NoticeStatus.PUBLISHING, NoticeStatus.PUBLISHED, NoticeStatus.FAILED);

    private final PublicHolidayRepository holidays;
    private final NoticeDraftRepository drafts;
    private final InstitutionNoticeRepository notices;
    private final AdminActionRepository actions;
    private final NoticeAuthoringService authoring;
    private final NoticeFanOutService fanOut;
    private final AdminAlerts adminAlerts;
    private final TransactionTemplate transaction;

    public List<Long> holidayIdsOn(LocalDate date) {
        return holidays.findByDateAd(date).stream().map(PublicHoliday::getId).toList();
    }

    /** Runs on its own thread so a slow AI call never blocks the scheduler. */
    @Async("holidayExecutor")
    public void prepareNoticesAsync(Long holidayId) {
        try {
            prepareNotices(holidayId);
        } catch (RuntimeException e) {
            log.error("Preparing notices failed for holiday {}", holidayId, e);
        }
    }

    void prepareNotices(Long holidayId) {
        PublicHoliday holiday = holiday(holidayId);
        ensureDrafts(holiday);                       // drafts first: admins must never see an empty notice
        for (Long institutionId : fanOut.openForEligibleInstitutions(holiday)) {
            alertQuietly(institutionId, holiday);    // one institution's problem must not stop the others
        }
    }

    /** Tries AI again for drafts that were written from the template, unless an institution already used them. */
    @Async("holidayExecutor")
    public void upgradeTemplateDraftsAsync(Long holidayId) {
        try {
            upgradeTemplateDrafts(holidayId);
        } catch (RuntimeException e) {
            log.error("Upgrading template drafts failed for holiday {}", holidayId, e);
        }
    }

    void upgradeTemplateDrafts(Long holidayId) {
        boolean hasTemplateDraft = drafts.findByHolidayId(holidayId).stream()
                .anyMatch(draft -> draft.getOrigin() == DraftOrigin.TEMPLATE);
        if (!hasTemplateDraft || notices.existsByHolidayIdAndStatusIn(holidayId, TEXT_IN_USE)) {
            return;
        }
        PublicHoliday holiday = holiday(holidayId);
        authoring.writeWithAi(holiday).ifPresent(fresh -> transaction.executeWithoutResult(status -> {
            if (notices.existsByHolidayIdAndStatusIn(holidayId, TEXT_IN_USE)) return; // re-check inside the transaction
            replaceDrafts(holidayId, fresh);
            log.info("Template drafts of holiday {} upgraded to AI text", holidayId);
        }));
    }

    /** Super admin pressed "regenerate": new AI text, but only while no institution is using the old text. */
    public void regenerate(Long holidayId, Long userId) {
        requireTextNotInUse(holidayId);
        PublicHoliday holiday = holiday(holidayId);

        WrittenNotices fresh = authoring.writeWithAi(holiday).orElseThrow(() ->
                new DraftingUnavailableException("AI is unavailable right now; existing drafts were kept"));

        transaction.executeWithoutResult(status -> {
            requireTextNotInUse(holidayId); // re-check inside the transaction
            replaceDrafts(holidayId, fresh);
            actions.save(AdminAction.of(holidayId, null, userId, AdminActionType.REGENERATED_DRAFTS));
        });
    }

    // ------------------------------------------------------------------ internals

    private void ensureDrafts(PublicHoliday holiday) {
        Long holidayId = holiday.getId();
        boolean needClosed = drafts.findByHolidayIdAndVariant(holidayId, NoticeVariant.CLOSED).isEmpty();
        boolean needOpen = drafts.findByHolidayIdAndVariant(holidayId, NoticeVariant.OPEN).isEmpty();
        if (!needClosed && !needOpen) {
            return; // already drafted
        }
        WrittenNotices written = authoring.writeWithFallback(holiday);
        if (needClosed) saveDraft(holidayId, NoticeVariant.CLOSED, written.closed(), written);
        if (needOpen) saveDraft(holidayId, NoticeVariant.OPEN, written.open(), written);
    }

    private void saveDraft(Long holidayId, NoticeVariant variant, WrittenNotice notice, WrittenNotices source) {
        try {
            drafts.save(NoticeDraft.create(holidayId, variant, notice.title(), notice.body(),
                    source.origin(), source.model()));
        } catch (DataIntegrityViolationException e) {
            log.debug("Draft {} for holiday {} was created by another server", variant, holidayId);
        }
    }

    private void replaceDrafts(Long holidayId, WrittenNotices fresh) {
        replaceDraft(holidayId, NoticeVariant.CLOSED, fresh.closed(), fresh);
        replaceDraft(holidayId, NoticeVariant.OPEN, fresh.open(), fresh);
    }

    private void replaceDraft(Long holidayId, NoticeVariant variant, WrittenNotice notice, WrittenNotices source) {
        NoticeDraft draft = drafts.findByHolidayIdAndVariant(holidayId, variant).orElse(null);
        if (draft == null) {
            drafts.save(NoticeDraft.create(holidayId, variant, notice.title(), notice.body(),
                    source.origin(), source.model()));
        } else {
            draft.replaceWith(notice.title(), notice.body(), source.origin(), source.model());
            drafts.save(draft);
        }
    }

    private void requireTextNotInUse(Long holidayId) {
        if (notices.existsByHolidayIdAndStatusIn(holidayId, TEXT_IN_USE)) {
            throw new NoticeConflictException("An institution has already approved text from these drafts");
        }
    }

    private void alertQuietly(Long institutionId, PublicHoliday holiday) {
        try {
            adminAlerts.approvalRequested(institutionId, holiday, false);
        } catch (RuntimeException e) {
            log.warn("Could not alert admins of institution {} about holiday {}", institutionId, holiday.getId(), e);
        }
    }

    private PublicHoliday holiday(Long holidayId) {
        return holidays.findById(holidayId)
                .orElseThrow(() -> new NoticeNotFoundException("Holiday not found: " + holidayId));
    }
}
