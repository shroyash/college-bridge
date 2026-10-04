package com.college.bridge.doubt.service;

import com.college.bridge.academic.repository.TeacherAssignmentRepository;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.exception.AccessDeniedException;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.common.tenant.TenantContext;
import com.college.bridge.doubt.dto.CreateDoubtAnswerRequest;
import com.college.bridge.doubt.dto.DoubtAnswerResponse;
import com.college.bridge.doubt.entity.Doubt;
import com.college.bridge.doubt.entity.DoubtAnswer;
import com.college.bridge.doubt.mapper.DoubtAnswerMapper;
import com.college.bridge.doubt.repository.DoubtAnswerRepository;
import com.college.bridge.doubt.repository.DoubtRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class DoubtAnswerService {

    private final DoubtRepository doubtRepository;
    private final DoubtAnswerRepository doubtAnswerRepository;
    private final UserRepository userRepository;
    private final TeacherAssignmentRepository teacherAssignmentRepository;
    private final DoubtAnswerMapper doubtAnswerMapper;
    private final org.springframework.context.ApplicationEventPublisher eventPublisher;

    @Transactional
    public DoubtAnswerResponse answerDoubt(
            Long doubtId,
            CreateDoubtAnswerRequest request,
            UserPrincipal principal
    ) {
        Long tenantId = TenantContext.requireTenant();

        Doubt doubt = findAccessibleDoubt(
                doubtId,
                principal,
                tenantId
        );

        if (principal.getStudentId() == null && principal.getTeacherId() == null) {
            throw new org.springframework.security.access.AccessDeniedException("Admins are not allowed to answer doubts.");
        }

        User user =
                userRepository
                        .findByIdAndInstitutionId(
                                principal.getUserId(),
                                tenantId
                        )
                        .orElseThrow(() ->
                                new ResourceNotFoundException(
                                        "User not found"
                                )
                        );

        boolean isTeacher = principal.getTeacherId() != null &&
                teacherAssignmentRepository.existsByTeacherSubjectAndTenant(
                        principal.getTeacherId(),
                        doubt.getSubject().getSubjectId(),
                        tenantId
                );

        DoubtAnswer answer = DoubtAnswer.builder()
                .doubt(doubt)
                .answeredBy(user)
                .answer(request.answer().trim())
                .isVerified(isTeacher)
                .build();

        DoubtAnswer saved =
                doubtAnswerRepository.save(answer);

        if (doubt.getStatus() == com.college.bridge.doubt.entity.DoubtStatus.OPEN) {
            doubt.setStatus(
                    com.college.bridge.doubt.entity.DoubtStatus.ANSWERED
            );
        }

        return doubtAnswerMapper.toResponse(saved);
    }

    public Page<DoubtAnswerResponse> getAnswers(
            Long doubtId,
            Boolean verified,
            Pageable pageable,
            UserPrincipal principal
    ) {
        Long tenantId = TenantContext.requireTenant();

        // Authorization check.
        findAccessibleDoubt(
                doubtId,
                principal,
                tenantId
        );

        return doubtAnswerRepository
                .findAnswersByDoubtAndTenant(
                        doubtId,
                        tenantId,
                        verified,
                        pageable
                )
                .map(doubtAnswerMapper::toResponse);
    }

    @Transactional
    public void verifyAnswer(
            Long doubtId,
            Long answerId,
            UserPrincipal principal
    ) {
        Long tenantId = TenantContext.requireTenant();

        if (principal.getTeacherId() == null) {
            throw new AccessDeniedException(
                    "Only teachers can verify answers"
            );
        }

        DoubtAnswer answer =
                doubtAnswerRepository
                        .findByIdAndDoubtAndTenant(
                                answerId,
                                doubtId,
                                tenantId
                        )
                        .orElseThrow(() ->
                                new ResourceNotFoundException(
                                        "Answer not found"
                                )
                        );

        Long subjectId =
                answer.getDoubt()
                        .getSubject()
                        .getSubjectId();

        boolean assigned =
                teacherAssignmentRepository
                        .existsByTeacherSubjectAndTenant(
                                principal.getTeacherId(),
                                subjectId,
                                tenantId
                        );

        if (!assigned) {
            throw new AccessDeniedException(
                    "You are not assigned to this subject"
            );
        }

        if (!answer.isVerified()) {
            answer.setVerified(true);
            long approvedVersion = System.currentTimeMillis();
            Long answerAuthorUserId = (answer.getAnsweredBy() != null) ? answer.getAnsweredBy().getUserId() : null;
            Long doubtAuthorUserId = (answer.getDoubt() != null && answer.getDoubt().getStudent() != null && answer.getDoubt().getStudent().getUser() != null)
                    ? answer.getDoubt().getStudent().getUser().getUserId()
                    : null;
            eventPublisher.publishEvent(new com.college.bridge.notification.event.AnswerApprovedEvent(
                    doubtId, answerId, principal.getUserId(), answerAuthorUserId, doubtAuthorUserId, tenantId, approvedVersion
            ));
        }
    }

    @Transactional
    public void verifyAnswerDirect(
            Long answerId,
            UserPrincipal principal
    ) {
        Long tenantId = TenantContext.requireTenant();

        if (principal.getTeacherId() == null) {
            throw new AccessDeniedException(
                    "Only teachers can verify answers"
            );
        }

        DoubtAnswer answer =
                doubtAnswerRepository
                        .findByIdAndTenant(
                                answerId,
                                tenantId
                        )
                        .orElseThrow(() ->
                                new ResourceNotFoundException(
                                        "Answer not found"
                                )
                        );

        Long subjectId =
                answer.getDoubt()
                        .getSubject()
                        .getSubjectId();

        boolean assigned =
                teacherAssignmentRepository
                        .existsByTeacherSubjectAndTenant(
                                principal.getTeacherId(),
                                subjectId,
                                tenantId
                        );

        if (!assigned) {
            throw new AccessDeniedException(
                    "You are not assigned to this subject"
            );
        }

        if (!answer.isVerified()) {
            answer.setVerified(true);
        }
    }

    private Doubt findAccessibleDoubt(
            Long doubtId,
            UserPrincipal principal,
            Long tenantId
    ) {
        if (principal.getStudentId() != null) {

            return doubtRepository
                    .findAccessibleByIdForStudent(
                            doubtId,
                            principal.getStudentId(),
                            tenantId
                    )
                    .orElseThrow(() ->
                            new ResourceNotFoundException(
                                    "Doubt not found"
                            )
                    );
        }

        if (principal.getTeacherId() != null) {

            return doubtRepository
                    .findAccessibleByIdForTeacher(
                            doubtId,
                            principal.getTeacherId(),
                            tenantId
                    )
                    .orElseThrow(() ->
                            new ResourceNotFoundException(
                                    "Doubt not found"
                            )
                    );
        }

        if (principal.getAuthorities().stream().anyMatch(a ->
                a.getAuthority().equals("ROLE_ADMIN") || a.getAuthority().equals("ROLE_SUPER_ADMIN"))) {

            return doubtRepository
                    .findAccessibleByIdForAdmin(
                            doubtId,
                            tenantId
                    )
                    .orElseThrow(() ->
                            new ResourceNotFoundException(
                                    "Doubt not found"
                            )
                    );
        }

        throw new AccessDeniedException(
                "You cannot access this doubt"
        );
    }
}