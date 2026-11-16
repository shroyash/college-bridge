package com.college.bridge.doubt.dto;

public record DoubtSummaryResponse(
        long total,
        long solved,
        long unsolved
) {
}
