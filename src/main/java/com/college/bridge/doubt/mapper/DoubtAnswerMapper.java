package com.college.bridge.doubt.mapper;

import com.college.bridge.doubt.dto.DoubtAnswerResponse;
import com.college.bridge.doubt.entity.DoubtAnswer;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface DoubtAnswerMapper {

    @Mapping(source = "answeredBy.userId", target = "answeredById")
    @Mapping(source = "answeredBy.name", target = "answeredByName")
    @Mapping(source = "answerId", target = "answerId")
    @Mapping(source = "answer", target = "answer")
    @Mapping(source = "verified", target = "verified")
    @Mapping(target = "answeredByTeacher", expression = "java(answer.getAnsweredBy() != null && com.college.bridge.auth.entity.UserRole.TEACHER.equals(answer.getAnsweredBy().getRole()))")
    @Mapping(source = "createdAt", target = "createdAt")
    DoubtAnswerResponse toResponse(DoubtAnswer answer);
}