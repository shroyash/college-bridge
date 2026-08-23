package com.college.bridge.auth.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BulkTransferRequest {

    @NotEmpty(message = "studentIds list must not be empty.")
    private List<Long> studentIds;

    @NotNull(message = "targetClassId is required.")
    private Long targetClassId;
}
