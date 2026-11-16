package com.college.bridge.holiday.application.notice;

import com.college.bridge.holiday.domain.InstitutionNotice;
import com.college.bridge.holiday.domain.InstitutionNoticeRepository;
import com.college.bridge.holiday.domain.NoticeStatus;
import com.college.bridge.holiday.domain.PublicHoliday;
import com.college.bridge.holiday.domain.PublicHolidayRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Use case: list an institution's approved (official) holiday notices. Approved = official, even if the push failed. */
@Service
@RequiredArgsConstructor
public class OfficialNoticeQueryService {

    private static final List<NoticeStatus> OFFICIAL = List.of(
            NoticeStatus.APPROVED, NoticeStatus.PUBLISHING, NoticeStatus.PUBLISHED, NoticeStatus.FAILED);

    private final InstitutionNoticeRepository notices;
    private final PublicHolidayRepository holidays;

    @Transactional(readOnly = true)
    public PagedResult<OfficialNoticeView> list(Long institutionId, Pageable pageable) {
        Page<InstitutionNotice> page =
                notices.findByInstitutionIdAndStatusInOrderByDecidedAtDesc(institutionId, OFFICIAL, pageable);

        List<Long> holidayIds = page.getContent().stream().map(InstitutionNotice::getHolidayId).toList();
        Map<Long, PublicHoliday> holidaysById = holidays.findAllById(holidayIds).stream()
                .collect(Collectors.toMap(PublicHoliday::getId, Function.identity()));

        return PagedResult.of(page.map(notice -> {
            PublicHoliday holiday = holidaysById.get(notice.getHolidayId());
            return new OfficialNoticeView(notice.getHolidayId(), holiday.getName(), holiday.getDateAd(),
                    notice.getApprovedVariant(), notice.getFinalTitle(), notice.getFinalBody(), notice.getDecidedAt());
        }));
    }
}
