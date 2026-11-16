package com.college.bridge.holiday.exception;

import com.college.bridge.holiday.controller.InstitutionNoticeController;
import com.college.bridge.holiday.application.notice.DraftingUnavailableException;
import com.college.bridge.holiday.application.port.CalendarUnavailableException;
import com.college.bridge.holiday.domain.NoticeConflictException;
import com.college.bridge.holiday.domain.NoticeForbiddenException;
import com.college.bridge.holiday.domain.NoticeInvalidException;
import com.college.bridge.holiday.domain.NoticeNotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * Maps domain/application errors to HTTP. The message is returned in the body on purpose
 * (server.error.include-message=never only hides the generic /error page).
 * If your project already has a global handler with a different body shape, adapt these mappings there.
 */
@RestControllerAdvice(basePackageClasses = InstitutionNoticeController.class)
class HolidayApiExceptionHandler {

    @ExceptionHandler(NoticeNotFoundException.class)
    ProblemDetail notFound(NoticeNotFoundException e) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, e.getMessage());
    }

    @ExceptionHandler(NoticeConflictException.class)
    ProblemDetail conflict(NoticeConflictException e) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, e.getMessage());
    }

    @ExceptionHandler(NoticeForbiddenException.class)
    ProblemDetail forbidden(NoticeForbiddenException e) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.FORBIDDEN, e.getMessage());
    }

    @ExceptionHandler(NoticeInvalidException.class)
    ProblemDetail invalid(NoticeInvalidException e) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, e.getMessage());
    }

    @ExceptionHandler({DraftingUnavailableException.class, CalendarUnavailableException.class})
    ProblemDetail upstreamUnavailable(RuntimeException e) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.BAD_GATEWAY, e.getMessage());
    }
}
