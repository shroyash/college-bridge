package com.college.bridge.doubt.mapper;

import com.college.bridge.doubt.dto.DoubtAnswerResponse;
import com.college.bridge.doubt.dto.DoubtResponse;
import com.college.bridge.doubt.entity.Doubt;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

@Mapper(componentModel = "spring")
public interface DoubtMapper {

    @Mapping(source = "doubt.subject.subjectId", target = "subjectId")
    @Mapping(source = "doubt.subject.name", target = "subjectName")
    @Mapping(source = "doubt.student.studentId", target = "studentId")
    @Mapping(source = "doubt.student.user.name", target = "studentName")
    @Mapping(source = "doubt.isHelpful", target = "helpful")
    @Mapping(source = "doubt.status", target = "status")
    @Mapping(source = "answerCount", target = "answerCount")
    @Mapping(source = "verifiedAnswerCount", target = "verifiedAnswerCount")
    @Mapping(
            target = "unverifiedAnswerCount",
            expression = "java(answerCount - verifiedAnswerCount)"
    )
    @Mapping(target = "answers", expression = "java(java.util.Collections.emptyList())")
    DoubtResponse toResponse(
            Doubt doubt,
            long answerCount,
            long verifiedAnswerCount
    );

    @Mapping(source = "doubt.subject.subjectId", target = "subjectId")
    @Mapping(source = "doubt.subject.name", target = "subjectName")
    @Mapping(source = "doubt.student.studentId", target = "studentId")
    @Mapping(source = "doubt.student.user.name", target = "studentName")
    @Mapping(source = "doubt.isHelpful", target = "helpful")
    @Mapping(source = "doubt.status", target = "status")
    @Mapping(source = "answerCount", target = "answerCount")
    @Mapping(source = "verifiedAnswerCount", target = "verifiedAnswerCount")
    @Mapping(
            target = "unverifiedAnswerCount",
            expression = "java(answerCount - verifiedAnswerCount)"
    )
    @Mapping(source = "answers", target = "answers")
    DoubtResponse toResponseWithAnswers(
            Doubt doubt,
            long answerCount,
            long verifiedAnswerCount,
            List<DoubtAnswerResponse> answers
    );
}