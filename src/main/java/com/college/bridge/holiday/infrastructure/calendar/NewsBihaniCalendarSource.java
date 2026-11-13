package com.college.bridge.holiday.infrastructure.calendar;

import com.college.bridge.holiday.application.port.CalendarUnavailableException;
import com.college.bridge.holiday.application.port.HolidayCalendarSource;
import com.college.bridge.holiday.config.HolidayProperties;
import com.college.bridge.holiday.domain.HolidayScope;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

import java.net.http.HttpClient;
import java.time.DateTimeException;
import java.time.Duration;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/** Adapter: reads the national holiday calendar from calendar.newsbihani.com. */
@Component
@Slf4j
class NewsBihaniCalendarSource implements HolidayCalendarSource {

    /** Only the fields we use; extra fields in the response are ignored. */
    @JsonIgnoreProperties(ignoreUnknown = true)
    record CalendarResponse(Integer count, List<Event> events) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    record Event(String titleEn, String adIso, BsDate date, String scope) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    record BsDate(int year, int month, int day) {}

    private final RestClient client;
    private final String holidayType;

    NewsBihaniCalendarSource(RestClient.Builder builder, HolidayProperties props) {
        JdkClientHttpRequestFactory factory = new JdkClientHttpRequestFactory(
                HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build());
        factory.setReadTimeout(Duration.ofSeconds(15));
        this.client = builder.baseUrl(props.api().baseUrl()).requestFactory(factory).build();
        this.holidayType = props.api().type();
    }

    @Override
    public List<CalendarEntry> fetchYear(int bsYear) {
        CalendarResponse response = request(bsYear);
        if (response == null || response.events() == null || response.events().isEmpty()) {
            throw new CalendarUnavailableException("Holiday API returned no events for BS " + bsYear);
        }
        if (response.count() != null && response.count() != response.events().size()) {
            log.warn("Holiday API says count={} but sent {} events for BS {}",
                    response.count(), response.events().size(), bsYear);
        }
        return response.events().stream()
                .map(this::toEntry)
                .flatMap(Optional::stream)
                .toList();
    }

    private CalendarResponse request(int bsYear) {
        try {
            return client.get()
                    .uri(uri -> uri.path("/api/holidays")
                            .queryParam("year", bsYear)
                            .queryParam("type", holidayType)
                            .build())
                    .retrieve()
                    .body(CalendarResponse.class);
        } catch (RestClientResponseException e) {
            throw new CalendarUnavailableException("Holiday API returned HTTP " + e.getStatusCode().value(), e);
        } catch (ResourceAccessException e) {
            throw new CalendarUnavailableException("Holiday API unreachable or timed out", e);
        }
    }

    /** Invalid entries are skipped (and logged) instead of failing the whole year. */
    private Optional<CalendarEntry> toEntry(Event event) {
        if (event.titleEn() == null || event.titleEn().isBlank() || event.adIso() == null || event.date() == null) {
            log.warn("Skipping incomplete calendar entry: {}", event);
            return Optional.empty();
        }
        try {
            LocalDate dateAd = LocalDate.parse(event.adIso());
            String dateBs = String.format("%04d-%02d-%02d", event.date().year(), event.date().month(), event.date().day());
            return Optional.of(new CalendarEntry(event.titleEn().trim(), dateAd, dateBs, toScope(event.scope())));
        } catch (DateTimeException e) {
            log.warn("Skipping calendar entry with invalid date '{}': {}", event.adIso(), event.titleEn());
            return Optional.empty();
        }
    }

    /**
     * The calendar describes scope in Nepali: "देशभर" (nationwide), "पहाडी जिल्ला" (hill districts),
     * "तराई जिल्ला" (Terai districts). Region words are checked first because a combined text such as
     * "देशभर तथा सुदूरपश्चिम" still means nationwide.
     */
    private HolidayScope toScope(String raw) {
        if (raw == null || raw.isBlank()) return HolidayScope.NATIONWIDE;
        if (raw.contains("पहाड")) return HolidayScope.HILLS;
        if (raw.contains("तराई")) return HolidayScope.TERAI;
        if (raw.contains("देशभर")) return HolidayScope.NATIONWIDE;
        log.warn("Unknown holiday scope '{}'; treating as nationwide", raw);
        return HolidayScope.NATIONWIDE;
    }
}
