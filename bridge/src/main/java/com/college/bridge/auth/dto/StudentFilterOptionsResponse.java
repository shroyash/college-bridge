package com.college.bridge.auth.dto;

import lombok.*;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StudentFilterOptionsResponse {
    private List<String> faculties;
    private List<Integer> semesters;
}
