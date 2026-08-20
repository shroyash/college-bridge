package com.college.bridge.academic;

import com.college.bridge.academic.dto.BatchCreateSubjectRequest;
import com.college.bridge.academic.dto.CreateAcademicClassRequest;
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
    @DisplayName("Should pass validation for valid dynamic faculties (BIT, BE_CIVIL, BSW, etc.)")
    void testValidFaculties(String faculty) {
        CreateAcademicClassRequest classReq = CreateAcademicClassRequest.builder()
                .faculty(faculty)
                .semester(1)
                .build();

        Set<ConstraintViolation<CreateAcademicClassRequest>> classViolations = validator.validate(classReq);
        assertTrue(classViolations.isEmpty(), "Expected no violations for valid faculty: " + faculty);

        CreateSubjectRequest subjectReq = CreateSubjectRequest.builder()
                .name("Introduction to Programming")
                .faculty(faculty)
                .semester(1)
                .creditHours(3)
                .build();

        Set<ConstraintViolation<CreateSubjectRequest>> subjectViolations = validator.validate(subjectReq);
        assertTrue(subjectViolations.isEmpty(), "Expected no violations for valid faculty: " + faculty);

        BatchCreateSubjectRequest batchReq = BatchCreateSubjectRequest.builder()
                .faculty(faculty)
                .semester(1)
                .subjects(java.util.List.of(
                        BatchCreateSubjectRequest.SubjectItem.builder().name("Math I").creditHours(3).build()
                ))
                .build();

        Set<ConstraintViolation<BatchCreateSubjectRequest>> batchViolations = validator.validate(batchReq);
        assertTrue(batchViolations.isEmpty(), "Expected no violations for valid faculty: " + faculty);
    }

    @Test
    @DisplayName("Should fail validation for empty / blank faculty string")
    void testEmptyFaculty() {
        CreateAcademicClassRequest request = CreateAcademicClassRequest.builder()
                .faculty("")
                .semester(1)
                .build();

        Set<ConstraintViolation<CreateAcademicClassRequest>> violations = validator.validate(request);
        assertFalse(violations.isEmpty(), "Expected validation failure for empty faculty");
    }

    @Test
    @DisplayName("Should fail validation for faculty with spaces or invalid characters")
    void testInvalidCharacterFaculty() {
        CreateAcademicClassRequest request = CreateAcademicClassRequest.builder()
                .faculty("bit program") // lowercase and space
                .semester(1)
                .build();

        Set<ConstraintViolation<CreateAcademicClassRequest>> violations = validator.validate(request);
        assertFalse(violations.isEmpty(), "Expected validation failure for faculty with invalid characters");
    }

    @Test
    @DisplayName("Should fail validation for faculty exceeding 20 characters")
    void testTooLongFaculty() {
        String longFaculty = "A".repeat(21); // 21 chars
        CreateAcademicClassRequest request = CreateAcademicClassRequest.builder()
                .faculty(longFaculty)
                .semester(1)
                .build();

        Set<ConstraintViolation<CreateAcademicClassRequest>> violations = validator.validate(request);
        assertFalse(violations.isEmpty(), "Expected validation failure for faculty > 20 characters");
    }
}
