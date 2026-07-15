package com.college.bridge.clazz.dto;

import com.college.bridge.academic.entity.Faculty;
import lombok.*;

/**
 * Response DTO representing a class and its assigned teacher.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClassResponse {

    private Long classId;
    private String className;
    private String subject;
    private Faculty faculty;
    private Integer semester;
    private String fcmTopicId;
    private String teacherName;
    private String teacherEmail;
}
