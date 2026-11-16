package com.college.bridge.holiday.domain;

import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface PublicHolidayRepository extends JpaRepository<PublicHoliday, Long> {

    Optional<PublicHoliday> findByDateAdAndName(LocalDate dateAd, String name);

    List<PublicHoliday> findByDateAd(LocalDate dateAd);

    /** All holidays of one BS year, e.g. prefix "2083-". */
    List<PublicHoliday> findByDateBsStartingWith(String bsYearPrefix);
}
