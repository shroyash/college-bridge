package com.college.bridge.academic;

import com.college.bridge.academic.entity.AcademicLevelType;
import com.college.bridge.academic.dto.AcademicLevelRequest;
import com.college.bridge.academic.dto.AcademicProgramRequest;
import com.college.bridge.academic.dto.BatchCreateSubjectRequest;
import com.college.bridge.academic.dto.CreateSubjectRequest;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

public class AcademicFacultyValidationTest {

    private static Validator validator;

    @BeforeAll
    static void setUp() {
        ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
        validator = factory.getValidator();
    }

    @ParameterizedTest
    @ValueSource(strings = {"BIT", "BE_CIVIL", "BSW", "BCA", "BBA", "BSC_CSIT"})
    @DisplayName("Should pass validation for valid program codes")
    void testValidPrograms(String code) {
        AcademicProgramRequest programReq = AcademicProgramRequest.builder()
                .name("Bachelor of " + code)
                .code(code)
                .build();

        Set<ConstraintViolation<AcademicProgramRequest>> programViolations = validator.validate(programReq);
        assertTrue(programViolations.isEmpty(), "Expected no violations for valid program code: " + code);

        AcademicLevelRequest levelReq = AcademicLevelRequest.builder()
                .name("First Semester")
                .levelNumber(1)
                .type(AcademicLevelType.SEMESTER)
                .build();

        Set<ConstraintViolation<AcademicLevelRequest>> levelViolations = validator.validate(levelReq);
        assertTrue(levelViolations.isEmpty(), "Expected no violations for level request");

        CreateSubjectRequest subjectReq = CreateSubjectRequest.builder()
                .name("Introduction to Programming")
                .levelId(1L)
                .creditHours(3)
                .build();

        Set<ConstraintViolation<CreateSubjectRequest>> subjectViolations = validator.validate(subjectReq);
        assertTrue(subjectViolations.isEmpty(), "Expected no violations for subject request");

        BatchCreateSubjectRequest batchReq = BatchCreateSubjectRequest.builder()
                .levelId(1L)
                .subjects(java.util.List.of(
                        BatchCreateSubjectRequest.SubjectItem.builder().name("Math I").creditHours(3).build()
                ))
                .build();

        Set<ConstraintViolation<BatchCreateSubjectRequest>> batchViolations = validator.validate(batchReq);
        assertTrue(batchViolations.isEmpty(), "Expected no violations for batch subject request");
    }

    @Test
    @DisplayName("Should fail validation for empty program code")
    void testEmptyProgramCode() {
        AcademicProgramRequest request = AcademicProgramRequest.builder()
                .name("Bachelor of Science")
                .code("")
                .build();

        Set<ConstraintViolation<AcademicProgramRequest>> violations = validator.validate(request);
        assertFalse(violations.isEmpty(), "Expected validation failure for empty code");
    }
}
