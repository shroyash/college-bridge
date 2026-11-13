package com.college.bridge.holiday.application.notice;

import org.springframework.data.domain.Page;

import java.util.List;

/** Stable JSON shape for pages (Spring's PageImpl is not meant to be serialised directly). */
public record PagedResult<T>(List<T> content, int page, int size, long totalElements, int totalPages) {

    public static <T> PagedResult<T> of(Page<T> page) {
        return new PagedResult<>(page.getContent(), page.getNumber(), page.getSize(),
                page.getTotalElements(), page.getTotalPages());
    }
}
