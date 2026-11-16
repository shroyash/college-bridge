package com.college.bridge.holiday.domain;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.time.LocalDate;

/** A public holiday from the national calendar. Platform-wide: shared by every institution. */
@Entity
@Table(name = "holidays",
        uniqueConstraints = @UniqueConstraint(name = "uq_holidays_date_name", columnNames = {"date_ad", "name"}))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PublicHoliday {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "date_ad", nullable = false)
    private LocalDate dateAd;

    @Column(name = "date_bs", nullable = false, length = 16)
    private String dateBs;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, length = 32)
    private String type;

    /** Nullable in the database so rows created before this column existed still load (read as NATIONWIDE). */
    @Enumerated(EnumType.STRING)
    @Column(length = 16)
    private HolidayScope scope;

    @Column(name = "fetched_at", nullable = false)
    private Instant fetchedAt;

    public static PublicHoliday create(LocalDate dateAd, String dateBs, String name, String type,
                                       HolidayScope scope, Instant fetchedAt) {
        PublicHoliday holiday = new PublicHoliday();
        holiday.dateAd = dateAd;
        holiday.name = name;
        holiday.refresh(dateBs, type, scope, fetchedAt);
        return holiday;
    }

    /** Re-applies the latest calendar values to an existing holiday. */
    public void refresh(String dateBs, String type, HolidayScope scope, Instant fetchedAt) {
        this.dateBs = dateBs;
        this.type = type;
        this.scope = scope;
        this.fetchedAt = fetchedAt;
    }

    public HolidayScope getScope() {
        return scope == null ? HolidayScope.NATIONWIDE : scope;
    }
}
