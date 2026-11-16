package com.college.bridge.academic.mapper;

import com.college.bridge.academic.dto.AcademicProgramResponse;
import com.college.bridge.academic.entity.AcademicProgram;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

@Mapper(componentModel = "spring")
public interface AcademicProgramMapper {

    @Mapping(target = "institutionId", source = "institution.institutionId")
    @Mapping(target = "createdAt", expression = "java(program.getCreatedAt() != null ? program.getCreatedAt().toString() : null)")
    AcademicProgramResponse toResponse(AcademicProgram program);

    List<AcademicProgramResponse> toResponseList(List<AcademicProgram> programs);
}
