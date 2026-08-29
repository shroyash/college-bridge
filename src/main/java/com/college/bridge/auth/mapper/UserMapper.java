package com.college.bridge.auth.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import com.college.bridge.auth.dto.UserProfileResponse;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.entity.User;

@Mapper(componentModel = "spring")
public interface UserMapper {

    @Mapping(target = "role", expression = "java(user.getRole() != null ? user.getRole().name() : null)")
    @Mapping(target = "status", expression = "java(user.getStatus() != null ? user.getStatus().name() : null)")
    @Mapping(target = "studentDetails", source = "student")
    @Mapping(target = "teacherId", source = "teacher.teacherId")
    UserProfileResponse toProfileResponse(User user, Student student, Teacher teacher);

    @Mapping(target = "studentId", source = "studentId")
    @Mapping(target = "levelId", source = "academicLevel.levelId")
    @Mapping(target = "levelName", source = "academicLevel.name")
    @Mapping(target = "levelNumber", source = "academicLevel.levelNumber")
    @Mapping(target = "levelType", source = "academicLevel.type")
    @Mapping(target = "programId", source = "academicLevel.program.programId")
    @Mapping(target = "programName", source = "academicLevel.program.name")
    @Mapping(target = "programCode", source = "academicLevel.program.code")
    UserProfileResponse.StudentProfileDetails mapStudentToDetails(Student student);

    default UserProfileResponse toProfileResponse(User user) {
        return toProfileResponse(user, null, null);
    }

    default UserProfileResponse toProfileResponse(User user, Student student) {
        return toProfileResponse(user, student, null);
    }
}