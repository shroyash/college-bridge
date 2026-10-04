package com.college.bridge.notification.service;

import com.college.bridge.academic.entity.ClassStatus;
import com.college.bridge.academic.entity.SubjectEnrollment;
import com.college.bridge.academic.entity.TeacherAssignment;
import com.college.bridge.academic.repository.AcademicLevelRepository;
import com.college.bridge.academic.repository.SubjectEnrollmentRepository;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.academic.repository.TeacherAssignmentRepository;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.repository.StudentRepository;
import com.college.bridge.auth.repository.TeacherRepository;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.exception.ResourceNotFoundException;
import com.college.bridge.common.exception.TenantMismatchException;
import com.college.bridge.common.tenant.TenantContext;
import com.college.bridge.institution.entity.Institution;
import com.college.bridge.institution.repository.InstitutionRepository;
import com.college.bridge.notification.dto.CreateNotificationRequest;
import com.college.bridge.notification.dto.NotificationInboxResponse;
import com.college.bridge.notification.dto.NotificationResponse;
import com.college.bridge.notification.dto.UnreadCountResponse;
import com.college.bridge.notification.entity.*;
import com.college.bridge.notification.repository.NotificationInboxReadRepository;
import com.college.bridge.notification.repository.NotificationJobRepository;
import com.college.bridge.notification.repository.NotificationRecipientRepository;
import com.college.bridge.notification.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.ZoneOffset;
import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final NotificationJobRepository jobRepository;
    private final NotificationRecipientRepository recipientRepository;
    private final NotificationInboxReadRepository inboxReadRepository;
    private final UserRepository userRepository;
    private final InstitutionRepository institutionRepository;
    private final AcademicLevelRepository academicLevelRepository;
    private final SubjectRepository subjectRepository;
    private final TeacherAssignmentRepository teacherAssignmentRepository;
    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final SubjectEnrollmentRepository enrollmentRepository;

    @Transactional
    public NotificationResponse createNotification(CreateNotificationRequest request, UserPrincipal principal) {
        // 1. Idempotency check
        if (request.getIdempotencyKey() != null && !request.getIdempotencyKey().isBlank()) {
            Optional<Notification> existingOpt = notificationRepository.findByIdempotencyKey(request.getIdempotencyKey().trim());
            if (existingOpt.isPresent()) {
                return mapToResponse(existingOpt.get());
            }
        }

        Long tenantId = TenantContext.get() != null ? TenantContext.get() : principal.getInstitutionId();
        if (tenantId == null) {
            throw new TenantMismatchException("Tenant context required");
        }
        Institution institution = principal.getUser().getInstitution();

        validateAuthorizationAndTarget(request, principal, tenantId);

        Notification notification = Notification.builder()
                .institution(institution)
                .title(request.getTitle().trim())
                .message(request.getBody().trim())
                .sender(principal.getUser())
                .targetType(request.getTargetType())
                .targetId(request.getTargetId())
                .idempotencyKey(request.getIdempotencyKey() != null ? request.getIdempotencyKey().trim() : null)
                .createdAt(Instant.now())
                .build();

        Notification savedNotification = notificationRepository.save(notification);

        // 5. If USERS, create NotificationRecipient records
        if (request.getTargetType() == NotificationTargetType.USERS) {
            Set<Long> uniqueUserIds = new HashSet<>(request.getUserIds());
            List<User> targetUsers = userRepository.findByUserIdInAndInstitutionId(new ArrayList<>(uniqueUserIds), tenantId);

            List<NotificationRecipient> recipients = new ArrayList<>();
            for (User u : targetUsers) {
                recipients.add(NotificationRecipient.builder()
                        .notification(savedNotification)
                        .user(u)
                        .deliveryStatus(RecipientDeliveryStatus.PENDING)
                        .build());
            }
            recipientRepository.saveAll(recipients);
        }

        // 6. Enqueue durable NotificationJob
        NotificationJob job = NotificationJob.builder()
                .notification(savedNotification)
                .institutionId(tenantId)
                .status(JobStatus.PENDING)
                .attemptCount(0)
                .maxAttempts(5)
                .nextAttemptAt(Instant.now())
                .createdAt(Instant.now())
                .build();

        jobRepository.save(job);

        return mapToResponse(savedNotification);
    }

    @Transactional(readOnly = true)
    public Page<NotificationInboxResponse> getUserInbox(UserPrincipal principal, Pageable pageable) {
        Long tenantId = TenantContext.get() != null ? TenantContext.get() : principal.getInstitutionId();
        if (tenantId == null) {
            return Page.empty(pageable);
        }

        Long userId = principal.getUserId();
        InboxScope scope = resolveScope(principal, tenantId);

        Page<Notification> page = notificationRepository.findUserInbox(
                tenantId,
                userId,
                scope.levelId,
                scope.subjectIds,
                scope.userCreatedAt,
                pageable);

        List<Long> ids = page.getContent().stream()
                .map(Notification::getNotificationId)
                .toList();
        Set<Long> readIds = inboxReadRepository.findReadNotificationIds(userId, ids);

        return page.map(n -> NotificationInboxResponse.builder()
                .notificationId(n.getNotificationId())
                .title(n.getTitle())
                .body(n.getBody())
                .senderId(n.getSender() != null ? n.getSender().getUserId() : null)
                .senderName(n.getSender() != null ? n.getSender().getName() : "System")
                .targetType(n.getTargetType())
                .targetId(n.getTargetId())
                .createdAt(n.getCreatedAt())
                .read(readIds.contains(n.getNotificationId()))
                .build());
    }

    @Transactional(readOnly = true)
    public UnreadCountResponse getUnreadCount(UserPrincipal principal) {
        Long tenantId = TenantContext.get() != null ? TenantContext.get() : principal.getInstitutionId();
        if (tenantId == null) {
            return UnreadCountResponse.builder().count(0L).build();
        }

        Long userId = principal.getUserId();
        InboxScope scope = resolveScope(principal, tenantId);

        long count = notificationRepository.countUnreadInbox(
                tenantId,
                userId,
                scope.levelId,
                scope.subjectIds,
                scope.userCreatedAt);

        return UnreadCountResponse.builder().count(count).build();
    }

    @Transactional
    public void markAsRead(Long notificationId, UserPrincipal principal) {
        Long tenantId = TenantContext.get() != null ? TenantContext.get() : principal.getInstitutionId();
        if (tenantId == null) {
            throw new AccessDeniedException("Super-admin inbox is not supported");
        }

        Long userId = principal.getUserId();
        InboxScope scope = resolveScope(principal, tenantId);

        boolean inScope = notificationRepository.isNotificationInUserInboxScope(
                notificationId,
                tenantId,
                userId,
                scope.levelId,
                scope.subjectIds,
                scope.userCreatedAt);

        if (!inScope) {
            throw new AccessDeniedException("Notification is not in your inbox scope");
        }

        inboxReadRepository.markReadNative(notificationId, userId);
    }

    private InboxScope resolveScope(UserPrincipal principal, Long tenantId) {
        Long userId = principal.getUserId();
        Long levelId = -1L;
        List<Long> subjectIds = new ArrayList<>();
        Instant userCreatedAt = Instant.EPOCH;

        if (principal.getUser() != null && principal.getUser().getCreatedAt() != null) {
            userCreatedAt = principal.getUser().getCreatedAt().toInstant(ZoneOffset.UTC);
        } else {
            Optional<User> userOpt = userRepository.findById(userId);
            if (userOpt.isPresent() && userOpt.get().getCreatedAt() != null) {
                userCreatedAt = userOpt.get().getCreatedAt().toInstant(ZoneOffset.UTC);
            }
        }

        if (principal.getRole() == UserRole.STUDENT) {
            Optional<Student> studentOpt = studentRepository.findByUser_UserId(userId);
            if (studentOpt.isPresent()) {
                Student student = studentOpt.get();
                if (student.getAcademicLevel() != null) {
                    levelId = student.getAcademicLevel().getLevelId();
                }
                List<SubjectEnrollment> enrollments = enrollmentRepository
                        .findActiveByStudentIdAndInstitutionId(student.getStudentId(), tenantId);
                for (SubjectEnrollment se : enrollments) {
                    if (se.getStatus() == ClassStatus.ACTIVE && se.getSubject() != null) {
                        subjectIds.add(se.getSubject().getSubjectId());
                    }
                }
            }
        } else if (principal.getRole() == UserRole.TEACHER) {
            Optional<Teacher> teacherOpt = teacherRepository.findByUser_UserId(userId);
            if (teacherOpt.isPresent()) {
                List<TeacherAssignment> assignments = teacherAssignmentRepository
                        .findActiveByTeacherIdAndInstitutionId(teacherOpt.get().getTeacherId(), tenantId);
                for (TeacherAssignment ta : assignments) {
                    if (ta.getSubject() != null) {
                        subjectIds.add(ta.getSubject().getSubjectId());
                    }
                }
            }
        }

        if (subjectIds.isEmpty()) {
            subjectIds.add(-1L);
        }

        return new InboxScope(levelId, subjectIds, userCreatedAt);
    }

    private record InboxScope(Long levelId, List<Long> subjectIds, Instant userCreatedAt) {}

    private void validateAuthorizationAndTarget(CreateNotificationRequest request, UserPrincipal principal, Long tenantId) {
        UserRole role = principal.getRole();

        if (role == UserRole.STUDENT) {
            throw new AccessDeniedException("Students are not authorized to dispatch notifications");
        }

        NotificationTargetType targetType = request.getTargetType();

        if (role == UserRole.TEACHER) {
            Long teacherUserId = principal.getUserId();

            switch (targetType) {
                case INSTITUTION -> throw new AccessDeniedException("Teachers cannot send college-wide notifications");
                case CLASS -> {
                    if (request.getTargetId() == null) {
                        throw new IllegalArgumentException("targetId (class/levelId) is required for CLASS target");
                    }
                    boolean teachesInLevel = teacherAssignmentRepository
                            .existsAssignmentForUserAndLevel(teacherUserId, request.getTargetId(), tenantId);
                    if (!teachesInLevel) {
                        throw new AccessDeniedException("Teacher does not teach any active subjects in academic level: " + request.getTargetId());
                    }
                }
                case SUBJECT -> {
                    if (request.getTargetId() == null) {
                        throw new IllegalArgumentException("targetId (subjectId) is required for SUBJECT target");
                    }
                    boolean teachesSubject = teacherAssignmentRepository
                            .existsAssignmentForUser(request.getTargetId(), teacherUserId, tenantId);
                    if (!teachesSubject) {
                        throw new AccessDeniedException("Teacher is not assigned to subject: " + request.getTargetId());
                    }
                }
                case USERS -> {
                    validateDirectUsersPayload(request, tenantId);
                    Set<Long> uniqueIds = new HashSet<>(request.getUserIds());
                    long authorizedCount = teacherAssignmentRepository
                            .countAuthorizedStudentsForTeacher(teacherUserId, new ArrayList<>(uniqueIds), tenantId);
                    if (authorizedCount != uniqueIds.size()) {
                        throw new AccessDeniedException("One or more recipient users are not active students enrolled in teacher's assigned subjects");
                    }
                }
            }
            return;
        }

        // ADMIN / SUPER_ADMIN
        switch (targetType) {
            case INSTITUTION -> {} // Allowed
            case CLASS -> {
                if (request.getTargetId() == null) {
                    throw new IllegalArgumentException("targetId is required for CLASS target");
                }
                academicLevelRepository.findActiveByIdAndInstitutionId(request.getTargetId(), tenantId)
                        .orElseThrow(() -> new ResourceNotFoundException("Academic level not found in tenant: " + request.getTargetId()));
            }
            case SUBJECT -> {
                if (request.getTargetId() == null) {
                    throw new IllegalArgumentException("targetId is required for SUBJECT target");
                }
                subjectRepository.findActiveByIdAndInstitutionId(request.getTargetId(), tenantId)
                        .orElseThrow(() -> new ResourceNotFoundException("Subject not found in tenant: " + request.getTargetId()));
            }
            case USERS -> {
                validateDirectUsersPayload(request, tenantId);
                Set<Long> uniqueIds = new HashSet<>(request.getUserIds());
                long count = userRepository.countByUserIdInAndInstitutionId(new ArrayList<>(uniqueIds), tenantId);
                if (count != uniqueIds.size()) {
                    throw new TenantMismatchException("One or more target users do not belong to institution: " + tenantId);
                }
            }
        }
    }

    private void validateDirectUsersPayload(CreateNotificationRequest request, Long tenantId) {
        if (request.getUserIds() == null || request.getUserIds().isEmpty()) {
            throw new IllegalArgumentException("userIds list cannot be empty for USERS target type");
        }
        if (request.getUserIds().size() > 500) {
            throw new IllegalArgumentException("Direct notification recipient limit is 500 users per request");
        }
    }

    private NotificationResponse mapToResponse(Notification n) {
        return NotificationResponse.builder()
                .notificationId(n.getNotificationId())
                .institutionId(n.getInstitution() != null ? n.getInstitution().getInstitutionId() : null)
                .senderId(n.getSender() != null ? n.getSender().getUserId() : null)
                .senderName(n.getSender() != null ? n.getSender().getName() : "System")
                .title(n.getTitle())
                .body(n.getBody())
                .targetType(n.getTargetType())
                .targetId(n.getTargetId())
                .status("ACCEPTED")
                .idempotencyKey(n.getIdempotencyKey())
                .createdAt(n.getCreatedAt())
                .build();
    }
}
