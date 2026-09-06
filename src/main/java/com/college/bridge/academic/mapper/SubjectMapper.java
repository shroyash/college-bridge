package com.college.bridge.academic.mapper;

import com.college.bridge.academic.dto.*;
import com.college.bridge.academic.entity.AcademicLevel;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.entity.Teacher;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

@Mapper(componentModel = "spring")
public interface SubjectMapper {

    @Mapping(target = "levelId", source = "academicLevel.levelId")
    @Mapping(target = "levelName", source = "academicLevel.name")
    @Mapping(target = "programId", source = "academicLevel.program.programId")
    @Mapping(target = "programName", source = "academicLevel.program.name")
    @Mapping(target = "teacherName", ignore = true)
    SubjectResponse toResponse(Subject subject);

    @Mapping(target = "subjectId", source = "subject.subjectId")
    @Mapping(target = "name", source = "subject.name")
    @Mapping(target = "code", source = "subject.code")
    @Mapping(target = "creditHours", source = "subject.creditHours")
    @Mapping(target = "fcmTopicId", source = "subject.fcmTopicId")
    @Mapping(target = "levelId", source = "subject.academicLevel.levelId")
    @Mapping(target = "levelName", source = "subject.academicLevel.name")
    @Mapping(target = "programId", source = "subject.academicLevel.program.programId")
    @Mapping(target = "programName", source = "subject.academicLevel.program.name")
    @Mapping(target = "teacherName", source = "teacherName")
    SubjectResponse toResponse(Subject subject, String teacherName);

    List<SubjectResponse> toResponseList(List<Subject> subjects);

    @Mapping(target = "subjectId", source = "subject.subjectId")
    @Mapping(target = "subjectName", source = "subject.name")
    @Mapping(target = "code", source = "subject.code")
    @Mapping(target = "creditHours", source = "subject.creditHours")
    @Mapping(target = "academicLevel.levelId", source = "subject.academicLevel.levelId")
    @Mapping(target = "academicLevel.name", source = "subject.academicLevel.name")
    @Mapping(target = "academicLevel.levelNumber", source = "subject.academicLevel.levelNumber")
    @Mapping(target = "academicLevel.type", source = "subject.academicLevel.type")
    @Mapping(target = "academicProgram.programId", source = "subject.academicLevel.program.programId")
    @Mapping(target = "academicProgram.name", source = "subject.academicLevel.program.name")
    @Mapping(target = "academicProgram.code", source = "subject.academicLevel.program.code")
    @Mapping(target = "teacher", source = "teacher")
    @Mapping(target = "students", source = "students")
    @Mapping(target = "studentCount", expression = "java(students.size())")
    SubjectDetailResponse toDetailResponse(
            Subject subject,
            Teacher teacher,
            List<ClassStudentResponse> students
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
    @Mapping(target = "fullName", expression = "java(student.getUser() != null ? student.getUser().getFullName() : \"Unknown\")")
    @Mapping(target = "email", expression = "java(student.getUser() != null ? student.getUser().getEmail() : \"\")")
    @Mapping(target = "status", expression = "java(student.getUser() != null && student.getUser().getStatus() != null ? student.getUser().getStatus().name() : \"ACTIVE\")")
    ClassStudentResponse toClassStudentResponse(
            Student student
    );

    List<ClassStudentResponse> toClassStudentResponseList(List<Student> students);

    @Mapping(target = "teacherId", source = "teacher.teacherId")
    @Mapping(target = "userId", source = "teacher.user.userId")
    @Mapping(target = "fullName", expression = "java(teacher.getUser() != null ? teacher.getUser().getFullName() : \"Unknown\")")
    @Mapping(target = "email", expression = "java(teacher.getUser() != null ? teacher.getUser().getEmail() : \"\")")
    @Mapping(target = "assignedSubjects", source = "assignedSubjectNames")
    @Mapping(target = "isClassTeacher", constant = "false")
    ClassTeacherResponse toClassTeacherResponse(Teacher teacher, List<String> assignedSubjectNames);

    @Mapping(target = "classId", source = "level.levelId")
    @Mapping(target = "displayName", expression = "java(level.getProgram() != null ? level.getProgram().getCode() + \" - \" + level.getName() : level.getName())")
    @Mapping(target = "faculty", expression = "java(level.getProgram() != null ? level.getProgram().getCode() : \"\")")
    @Mapping(target = "semester", source = "level.levelNumber")
    @Mapping(target = "totalStudents", expression = "java(students.size())")
    @Mapping(target = "institutionId", expression = "java(level.getProgram() != null && level.getProgram().getInstitution() != null ? level.getProgram().getInstitution().getInstitutionId() : null)")
    @Mapping(target = "institutionName", expression = "java(level.getProgram() != null && level.getProgram().getInstitution() != null ? level.getProgram().getInstitution().getName() : \"\")")
    @Mapping(target = "createdBy", constant = "Institution Admin")
    @Mapping(target = "createdAt", expression = "java(level.getCreatedAt() != null ? level.getCreatedAt().toString() : \"\")")
    @Mapping(target = "students", source = "students")
    @Mapping(target = "teachers", source = "teachers")
    ClassDetailResponse toClassDetailResponse(AcademicLevel level, List<ClassStudentResponse> students, List<ClassTeacherResponse> teachers);
}
