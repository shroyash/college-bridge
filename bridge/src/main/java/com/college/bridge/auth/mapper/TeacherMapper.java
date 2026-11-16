package com.college.bridge.auth.mapper;

import com.college.bridge.auth.dto.CreateTeacherRequest;
import com.college.bridge.auth.dto.TeacherResponse;
import com.college.bridge.auth.dto.UpdateTeacherRequest;
import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.entity.User;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;


@Mapper(componentModel = "spring")
public interface TeacherMapper {


    @Mapping(target = "userId", ignore = true)
    @Mapping(target = "passwordHash", source = "password")
    @Mapping(target = "role", ignore = true)
    @Mapping(target = "status", ignore = true)
    @Mapping(target = "imageUrl", ignore = true)
    @Mapping(target = "fcmToken", ignore = true)
    @Mapping(target = "deleted", ignore = true)
    @Mapping(target = "deletedAt", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "version", ignore = true)
    User toUser(CreateTeacherRequest request);


    @Mapping(target = "teacherId", ignore = true)
    @Mapping(target = "user", source = "user")
    @Mapping(target = "assignments", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "version", ignore = true)
    Teacher toTeacher(User user);


    @Mapping(target = "userId", ignore = true)
    @Mapping(target = "passwordHash", ignore = true)
    @Mapping(target = "role", ignore = true)
    @Mapping(target = "status", ignore = true)
    @Mapping(target = "imageUrl", ignore = true)
    @Mapping(target = "fcmToken", ignore = true)
    @Mapping(target = "deleted", ignore = true)
    @Mapping(target = "deletedAt", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "version", ignore = true)
    void updateUser(
            UpdateTeacherRequest request,
            @MappingTarget User user
    );


    @Mapping(target = "teacherId", source = "teacherId")
    @Mapping(target = "userId", source = "user.userId")
    @Mapping(target = "name", source = "user.name")
    @Mapping(target = "email", source = "user.email")
    @Mapping(target = "status", source = "user.status")
    @Mapping(target = "createdAt", source = "user.createdAt")
    TeacherResponse toResponse(Teacher teacher);
}