package com.college.bridge.academic.mapper;

import com.college.bridge.academic.dto.TeacherAssignmentResponse;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.entity.TeacherAssignment;
import com.college.bridge.auth.entity.Teacher;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface TeacherAssignmentMapper {

    @Mapping(target = "assignmentId", ignore = true)
    @Mapping(target = "assignedAt", ignore = true)
    @Mapping(target = "version", ignore = true)
    TeacherAssignment toEntity(
            Teacher teacher,
            Subject subject
    );

    @Mapping(target = "assignmentId", source = "assignmentId")
    @Mapping(target = "subjectId", source = "subject.subjectId")
    @Mapping(target = "subjectName", source = "subject.name")
    @Mapping(target = "faculty", source = "subject.faculty")
    @Mapping(target = "semester", source = "subject.semester")
    TeacherAssignmentResponse toResponse(TeacherAssignment entity);
}