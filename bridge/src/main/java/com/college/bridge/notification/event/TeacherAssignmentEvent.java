package com.college.bridge.notification.event;

import java.util.List;

public record TeacherAssignmentEvent(
        Long teacherId,
        Long teacherUserId,
        Long institutionId,
        Long actorUserId,
        List<String> addedSubjectNames,
        List<String> removedSubjectNames,
        List<Long> addedSubjectIds,
        List<Long> removedSubjectIds,
        String changeId
) {}
