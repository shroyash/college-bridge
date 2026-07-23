package com.college.bridge.auth.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import com.college.bridge.auth.dto.UserProfileResponse;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.entity.User;

@Mapper(componentModel = "spring")
public interface UserMapper {

    @Mapping(target = "role", expression = "java(user.getRole() != null ? user.getRole().name() : null)")
    @Mapping(target = "status", expression = "java(user.getStatus() != null ? user.getStatus().name() : null)")
    @Mapping(target = "studentDetails", source = "student")
    UserProfileResponse toProfileResponse(User user, Student student);

    @Mapping(target = "academicClassId", source = "academicClass.classId")
    @Mapping(target = "faculty", source = "academicClass.faculty")
    @Mapping(target = "semester", source = "academicClass.semester")
    UserProfileResponse.StudentProfileDetails mapStudentToDetails(Student student);

    default UserProfileResponse toProfileResponse(User user) {
        return toProfileResponse(user, null);
    }
}
