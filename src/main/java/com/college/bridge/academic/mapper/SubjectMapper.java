package com.college.bridge.academic.mapper;

import com.college.bridge.academic.dto.ClassStudentResponse;
import com.college.bridge.academic.dto.SubjectDetailResponse;
import com.college.bridge.academic.dto.SubjectResponse;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.entity.Teacher;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface SubjectMapper {

    SubjectResponse toResponse(Subject subject);

    @Mapping(target = "teacherName", source = "teacherName")
    SubjectResponse toResponse(Subject subject, String teacherName);

    @Mapping(target = "subjectId", source = "subject.subjectId")
    @Mapping(target = "subjectName", source = "subject.name")
    @Mapping(target = "code", source = "subject.code")
    @Mapping(target = "creditHours", source = "subject.creditHours")

    @Mapping(
            target = "academicLevel.levelId",
            source = "subject.academicLevel.levelId"
    )
    @Mapping(
            target = "academicLevel.name",
            source = "subject.academicLevel.name"
    )
    @Mapping(
            target = "academicLevel.levelNumber",
            source = "subject.academicLevel.levelNumber"
    )
    @Mapping(
            target = "academicLevel.type",
            source = "subject.academicLevel.type"
    )

    @Mapping(
            target = "academicProgram.programId",
            source = "subject.academicLevel.program.programId"
    )
    @Mapping(
            target = "academicProgram.name",
            source = "subject.academicLevel.program.name"
    )
    @Mapping(
            target = "academicProgram.code",
            source = "subject.academicLevel.program.code"
    )

    @Mapping(target = "teacher", source = "teacher")
    @Mapping(target = "students", source = "students")
    @Mapping(target = "studentCount", expression = "java(students.size())")
    SubjectDetailResponse toDetailResponse(
            Subject subject,
            Teacher teacher,
            java.util.List<ClassStudentResponse> students
    );

    @Mapping(target = "teacherId", source = "teacherId")
    @Mapping(target = "userId", source = "user.userId")
    @Mapping(target = "name", source = "user.fullName")
    @Mapping(target = "email", source = "user.email")
    SubjectDetailResponse.TeacherInfoDto toTeacherInfo(
            Teacher teacher
    );

    @Mapping(target = "studentId", source = "studentId")
    @Mapping(target = "userId", source = "user.userId")
    @Mapping(target = "fullName", source = "user.fullName")
    @Mapping(target = "email", source = "user.email")
    @Mapping(target = "status", source = "user.status")
    ClassStudentResponse toClassStudentResponse(
            Student student
    );
}
