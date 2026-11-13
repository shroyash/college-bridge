package com.college.bridge.holiday.application.notice;

import com.college.bridge.holiday.application.port.InstitutionDirectory;
import com.college.bridge.holiday.application.port.InstitutionDirectory.InstitutionRef;
import com.college.bridge.holiday.domain.InstitutionNotice;
import com.college.bridge.holiday.domain.InstitutionNoticeRepository;
import com.college.bridge.holiday.domain.PublicHoliday;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

/**
 * Use case: give every eligible institution (whose region the holiday applies to) its own undecided notice.
 * Idempotent, so re-running picks up institutions that were approved after the first run.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class NoticeFanOutService {

    private final InstitutionDirectory institutions;
    private final InstitutionNoticeRepository notices;

    /** @return ids of institutions that got a NEW notice in this run (only those should be alerted) */
    public List<Long> openForEligibleInstitutions(PublicHoliday holiday) {
        List<Long> newlyOpened = new ArrayList<>();
        for (InstitutionRef institution : institutions.eligibleInstitutions()) {
            if (!holiday.getScope().appliesTo(institution.region())) {
                continue; // e.g. a Terai-only holiday is not offered to a hill college
            }
            if (openIfAbsent(holiday.getId(), institution.id())) {
                newlyOpened.add(institution.id());
            }
        }
        return newlyOpened;
    }

    private boolean openIfAbsent(Long holidayId, Long institutionId) {
        if (notices.existsByHolidayIdAndInstitutionId(holidayId, institutionId)) {
            return false;
        }
        try {
            notices.save(InstitutionNotice.awaitingDecision(holidayId, institutionId));
            return true;
        } catch (DataIntegrityViolationException e) {
            log.debug("Notice for holiday {} / institution {} was opened by another server", holidayId, institutionId);
            return false;
        }
    }
}
