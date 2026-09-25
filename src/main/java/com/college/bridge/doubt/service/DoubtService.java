package com.college.bridge.doubt.service;

import com.college.bridge.academic.entity.ClassStatus;
import com.college.bridge.academic.entity.SubjectEnrollment;
import com.college.bridge.academic.repository.SubjectEnrollmentRepository;
import com.college.bridge.academic.repository.TeacherAssignmentRepository;
import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.exception.AccessDeniedException;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.common.tenant.TenantContext;
import com.college.bridge.doubt.dto.CreateDoubtRequest;
import com.college.bridge.doubt.dto.DoubtAnswerCountProjection;
import com.college.bridge.doubt.dto.DoubtResponse;
import com.college.bridge.doubt.entity.Doubt;
import com.college.bridge.doubt.repository.DoubtAnswerRepository;
import com.college.bridge.doubt.repository.DoubtRepository;
import com.college.bridge.doubt.mapper.DoubtMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import com.college.bridge.doubt.dto.DoubtAnswerResponse;
import com.college.bridge.doubt.dto.DoubtSummaryResponse;
import com.college.bridge.doubt.mapper.DoubtAnswerMapper;
import com.college.bridge.doubt.entity.DoubtAnswer;


@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class DoubtService {

    private final DoubtRepository doubtRepository;
    private final DoubtAnswerRepository doubtAnswerRepository;
    private final SubjectEnrollmentRepository subjectEnrollmentRepository;
    private final TeacherAssignmentRepository teacherAssignmentRepository;
    private final DoubtMapper doubtMapper;
    private final DoubtAnswerMapper doubtAnswerMapper;

    @Transactional
    public DoubtResponse createDoubt(
            CreateDoubtRequest request,
            UserPrincipal principal
    ) {
        Long tenantId = TenantContext.requireTenant();

        if (principal.getStudentId() == null) {
            throw new AccessDeniedException(
                    "Only students can create doubts"
            );
        }

        SubjectEnrollment enrollment =
                subjectEnrollmentRepository
                        .findActiveEnrollment(
                                principal.getStudentId(),
                                request.subjectId(),
                                tenantId,
                                ClassStatus.ACTIVE
                        )
                        .orElseThrow(() ->
                                new AccessDeniedException(
                                        "You are not enrolled in this subject"
                                )
                        );

        Doubt doubt = Doubt.builder()
                .student(enrollment.getStudent())
                .subject(enrollment.getSubject())
                .question(request.question().trim())
                .build();

        Doubt saved = doubtRepository.save(doubt);

        return doubtMapper.toResponse(
                saved,
                0L,
                0L
        );
    }

    public Page<DoubtResponse> getDoubts(
            UserPrincipal principal,
            Long subjectId,
            String search,
            Pageable pageable
    ) {
        Long tenantId = TenantContext.requireTenant();

        String normalizedSearch =
                StringUtils.hasText(search)
                        ? search.trim()
                        : null;

        Page<Doubt> doubts;

        if (principal.getStudentId() != null) {

            doubts = doubtRepository.findAccessibleForStudent(
                    principal.getStudentId(),
                    subjectId,
                    tenantId,
                    normalizedSearch,
                    pageable
            );

        } else if (principal.getTeacherId() != null) {

            doubts = doubtRepository.findAccessibleForTeacher(
                    principal.getTeacherId(),
                    subjectId,
                    tenantId,
                    normalizedSearch,
                    pageable
            );

        } else if (principal.getAuthorities().stream().anyMatch(a ->
                a.getAuthority().equals("ROLE_ADMIN") || a.getAuthority().equals("ROLE_SUPER_ADMIN"))) {

            doubts = doubtRepository.findAccessibleForAdmin(
                    subjectId,
                    tenantId,
                    normalizedSearch,
                    pageable
            );

        } else {
            throw new AccessDeniedException(
                    "You cannot access this doubts"
            );
        }

        return mapWithAnswerCounts(doubts, tenantId);
    }

    public DoubtResponse getDoubt(
            Long doubtId,
            UserPrincipal principal
    ) {
        Long tenantId = TenantContext.requireTenant();

        Doubt doubt = findAccessibleDoubt(
                doubtId,
                principal,
                tenantId
        );

        Map<Long, DoubtAnswerCountProjection> counts =
                getAnswerCounts(
                        List.of(doubtId),
                        tenantId
                );

        DoubtAnswerCountProjection count =
                counts.get(doubtId);

        long answerCount =
                count != null
                        ? count.getAnswerCount()
                        : 0L;

        long verifiedAnswerCount =
                count != null
                        ? count.getVerifiedAnswerCount()
                        : 0L;

        List<DoubtAnswer> answerEntities =
                doubtAnswerRepository.findAllByDoubtAndTenantList(
                        doubtId,
                        tenantId
                );

        List<DoubtAnswerResponse> answers =
                answerEntities.stream()
                        .map(doubtAnswerMapper::toResponse)
                        .toList();

        return doubtMapper.toResponseWithAnswers(
                doubt,
                answerCount,
                verifiedAnswerCount,
                answers
        );
    }

    public DoubtSummaryResponse getDoubtSummary(
            Long subjectId,
            UserPrincipal principal
    ) {
        Long tenantId = TenantContext.requireTenant();

        if (principal.getTeacherId() != null) {
            if (subjectId != null) {
                boolean assigned = teacherAssignmentRepository.existsByTeacherSubjectAndTenant(
                        principal.getTeacherId(), subjectId, tenantId);
                if (!assigned) {
                    throw new AccessDeniedException("Access denied: You are not assigned to this subject");
                }
            }
            long total = doubtRepository.countTotalForTeacher(principal.getTeacherId(), subjectId, tenantId);
            long solved = doubtRepository.countSolvedForTeacher(principal.getTeacherId(), subjectId, tenantId);
            long unsolved = doubtRepository.countUnsolvedForTeacher(principal.getTeacherId(), subjectId, tenantId);
            return new DoubtSummaryResponse(total, solved, unsolved);
        }

        if (principal.getStudentId() != null) {
            if (subjectId != null) {
                boolean enrolled = subjectEnrollmentRepository.existsByStudentSubjectAndTenantAndStatus(
                        principal.getStudentId(), subjectId, tenantId, ClassStatus.ACTIVE);
                if (!enrolled) {
                    throw new AccessDeniedException("Access denied: You are not enrolled in this subject");
                }
            }
            long total = doubtRepository.countTotalForStudent(principal.getStudentId(), subjectId, tenantId);
            long solved = doubtRepository.countSolvedForStudent(principal.getStudentId(), subjectId, tenantId);
            long unsolved = doubtRepository.countUnsolvedForStudent(principal.getStudentId(), subjectId, tenantId);
            return new DoubtSummaryResponse(total, solved, unsolved);
        }

        long total = doubtRepository.countTotalBySubjectAndTenant(subjectId, tenantId);
        long solved = doubtRepository.countSolvedBySubjectAndTenant(subjectId, tenantId);
        long unsolved = doubtRepository.countUnsolvedBySubjectAndTenant(subjectId, tenantId);

        return new DoubtSummaryResponse(total, solved, unsolved);
    }

    @Transactional
    public DoubtResponse markHelpful(
            Long doubtId,
            UserPrincipal principal
    ) {
        Long tenantId = TenantContext.requireTenant();

        Doubt doubt = findAccessibleDoubt(
                doubtId,
                principal,
                tenantId
        );

        if (principal.getStudentId() == null || !doubt.getStudent().getStudentId().equals(principal.getStudentId())) {
            throw new AccessDeniedException(
                    "Only the student who asked this doubt can mark it as helpful"
            );
        }

        doubt.setIsHelpful(!Boolean.TRUE.equals(doubt.getIsHelpful()));
        Doubt saved = doubtRepository.save(doubt);

        Map<Long, DoubtAnswerCountProjection> counts = getAnswerCounts(List.of(doubtId), tenantId);
        DoubtAnswerCountProjection count = counts.get(doubtId);
        long answerCount = count != null ? count.getAnswerCount() : 0L;
        long verifiedAnswerCount = count != null ? count.getVerifiedAnswerCount() : 0L;

        return doubtMapper.toResponse(saved, answerCount, verifiedAnswerCount);
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

    private Page<DoubtResponse> mapWithAnswerCounts(
            Page<Doubt> doubts,
            Long tenantId
    ) {
        List<Long> doubtIds =
                doubts.getContent()
                        .stream()
                        .map(Doubt::getDoubtId)
                        .toList();

        if (doubtIds.isEmpty()) {
            return doubts.map(doubt ->
                    doubtMapper.toResponse(
                            doubt,
                            0L,
                            0L
                    )
            );
        }

        Map<Long, DoubtAnswerCountProjection> counts =
                getAnswerCounts(
                        doubtIds,
                        tenantId
                );

        return doubts.map(doubt -> {

            DoubtAnswerCountProjection count =
                    counts.get(doubt.getDoubtId());

            long answerCount =
                    count != null
                            ? count.getAnswerCount()
                            : 0L;

            long verifiedAnswerCount =
                    count != null
                            ? count.getVerifiedAnswerCount()
                            : 0L;

            return doubtMapper.toResponse(
                    doubt,
                    answerCount,
                    verifiedAnswerCount
            );
        });
    }

    private Map<Long, DoubtAnswerCountProjection> getAnswerCounts(
            List<Long> doubtIds,
            Long tenantId
    ) {
        if (doubtIds.isEmpty()) {
            return Map.of();
        }

        return doubtAnswerRepository
                .countByDoubtIdsAndTenant(
                        doubtIds,
                        tenantId
                )
                .stream()
                .collect(Collectors.toMap(
                        DoubtAnswerCountProjection::getDoubtId,
                        projection -> projection
                ));
    }
}