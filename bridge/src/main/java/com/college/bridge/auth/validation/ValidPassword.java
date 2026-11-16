package com.college.bridge.auth.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.*;

@Documented
@Constraint(validatedBy = PasswordValidator.class)
@Target({ElementType.FIELD, ElementType.ANNOTATION_TYPE})
@Retention(RetentionPolicy.RUNTIME)
public @interface ValidPassword {
    String message() default "Password must contain at least one uppercase letter, one lowercase letter, one digit, one special character, and be between 8 and 30 characters long";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}
