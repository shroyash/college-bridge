package com.college.bridge.academic.mapper;

import com.college.bridge.academic.dto.AcademicLevelResponse;
import com.college.bridge.academic.entity.AcademicLevel;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

@Mapper(componentModel = "spring")
public interface AcademicLevelMapper {

    @Mapping(target = "programId", source = "program.programId")
    @Mapping(target = "programName", source = "program.name")
    @Mapping(target = "programCode", source = "program.code")
    @Mapping(target = "createdAt", expression = "java(level.getCreatedAt() != null ? level.getCreatedAt().toString() : null)")
    AcademicLevelResponse toResponse(AcademicLevel level);

    List<AcademicLevelResponse> toResponseList(List<AcademicLevel> levels);
}
