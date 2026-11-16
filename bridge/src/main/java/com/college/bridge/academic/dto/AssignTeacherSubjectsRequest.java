package com.college.bridge.academic.dto;


import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import java.util.List;


@Getter
@Setter
public class AssignTeacherSubjectsRequest {

    @NotEmpty(message = "At least one subject must be selected.")
    private List<@NotNull Long> subjectIds;

}