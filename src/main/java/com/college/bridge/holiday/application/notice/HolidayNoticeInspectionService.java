package com.college.bridge.holiday.application.notice;

import com.college.bridge.holiday.domain.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;

/** Use case (super admin): inspect the shared drafts and how institutions are responding. No institution text is exposed. */
@Service
@RequiredArgsConstructor
public class HolidayNoticeInspectionService {

    private final PublicHolidayRepository holidays;
    private final NoticeDraftRepository drafts;
    private final InstitutionNoticeRepository notices;

    @Transactional(readOnly = true)
    public HolidayDraftsView inspect(Long holidayId) {
        PublicHoliday holiday = holidays.findById(holidayId)
                .orElseThrow(() -> new NoticeNotFoundException("Holiday not found: " + holidayId));

        List<DraftView> draftViews = drafts.findByHolidayId(holidayId).stream()
                .sorted(Comparator.comparing(NoticeDraft::getVariant))
                .map(draft -> new DraftView(draft.getVariant(), draft.getTitle(), draft.getBody(),
                        draft.getOrigin(), draft.getModel()))
                .toList();

        Map<NoticeStatus, Long> byStatus = new EnumMap<>(NoticeStatus.class);
        notices.countByStatus(holidayId).forEach(count -> byStatus.put(count.getStatus(), count.getTotal()));

        return new HolidayDraftsView(holiday.getId(), holiday.getName(), holiday.getDateAd(), holiday.getDateBs(),
                holiday.getScope(), draftViews, byStatus);
    }
}
