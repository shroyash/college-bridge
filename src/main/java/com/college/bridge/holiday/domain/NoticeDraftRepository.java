package com.college.bridge.holiday.domain;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

public interface NoticeDraftRepository extends JpaRepository<NoticeDraft, Long> {

    List<NoticeDraft> findByHolidayId(Long holidayId);

    Optional<NoticeDraft> findByHolidayIdAndVariant(Long holidayId, NoticeVariant variant);

    @Transactional
    void deleteByHolidayId(Long holidayId);
}
