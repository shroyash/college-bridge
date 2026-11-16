package com.college.bridge.notification.listener;

import com.college.bridge.academic.entity.ClassStatus;
import com.college.bridge.academic.entity.SubjectEnrollment;
import com.college.bridge.academic.entity.TeacherAssignment;
import com.college.bridge.academic.repository.SubjectEnrollmentRepository;
import com.college.bridge.academic.repository.TeacherAssignmentRepository;
import com.college.bridge.notification.dto.NotificationPublishRequest;
import com.college.bridge.notification.entity.NotificationTargetType;
import com.college.bridge.notification.entity.NotificationType;
import com.college.bridge.notification.event.*;
import com.college.bridge.notification.service.NotificationPublisher;
import com.college.bridge.notification.service.UserTopicRefreshService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.util.*;

@Component
@RequiredArgsConstructor
@Slf4j
public class NotificationDomainEventListener {

    private final NotificationPublisher notificationPublisher;
    private final UserTopicRefreshService userTopicRefreshService;
    private final TeacherAssignmentRepository teacherAssignmentRepository;
    private final SubjectEnrollmentRepository subjectEnrollmentRepository;

    @Value("${notification.events.notify-classmates-on-doubt:true}")
    private boolean notifyClassmatesOnDoubt;

    @Value("${notification.events.notify-subject-students-on-teacher-assign:false}")
    private boolean notifyStudentsOnTeacherAssign;

    @Async("notificationTaskExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onDoubtPosted(DoubtPostedEvent event) {
        try {
            Set<Long> recipientUserIds = new LinkedHashSet<>();

            // 1. Teachers assigned to this subject in the same institution
            List<TeacherAssignment> assignments = teacherAssignmentRepository
                    .findBySubject_SubjectIdInAndTenantId(List.of(event.subjectId()), event.institutionId());
            for (TeacherAssignment ta : assignments) {
                if (ta.getTeacher() != null && ta.getTeacher().getUser() != null) {
                    recipientUserIds.add(ta.getTeacher().getUser().getUserId());
                }
            }

            // 2. Classmates enrolled in this subject (if configured)
            if (notifyClassmatesOnDoubt) {
                List<SubjectEnrollment> enrollments = subjectEnrollmentRepository.findBySubject_SubjectId(event.subjectId());
                for (SubjectEnrollment se : enrollments) {
                    if (se.getStatus() == ClassStatus.ACTIVE && se.getStudent() != null && se.getStudent().getUser() != null) {
                        Long instId = se.getStudent().getUser().getInstitution() != null
                                ? se.getStudent().getUser().getInstitution().getInstitutionId()
                                : null;
                        if (Objects.equals(instId, event.institutionId())) {
                            recipientUserIds.add(se.getStudent().getUser().getUserId());
                        }
                    }
                }
            }

            // Exclude author and actor
            if (event.authorUserId() != null) {
                recipientUserIds.remove(event.authorUserId());
            }
            if (event.actorUserId() != null) {
                recipientUserIds.remove(event.actorUserId());
            }

            if (recipientUserIds.isEmpty()) {
                log.debug("No recipients found for DoubtPostedEvent doubtId={}", event.doubtId());
                return;
            }

            String subjectName = (event.subjectName() != null && !event.subjectName().isBlank())
                    ? event.subjectName().trim()
                    : null;
            String body = (subjectName != null)
                    ? "A student has posted a new doubt in " + subjectName + ". Tap to view and respond."
                    : (event.preview() != null && !event.preview().isBlank()
                            ? (event.preview().length() > 100 ? event.preview().substring(0, 97) + "..." : event.preview())
                            : "A new doubt was posted in your subject.");

            notificationPublisher.publish(NotificationPublishRequest.builder()
                    .institutionId(event.institutionId())
                    .title("New Student Doubt")
                    .body(body)
                    .targetType(NotificationTargetType.USERS)
                    .targetId(event.doubtId())
                    .userIds(new ArrayList<>(recipientUserIds))
                    .type(NotificationType.DOUBT_POSTED)
                    .senderUserId(event.actorUserId())
                    .idempotencyKey("DOUBT_POSTED:" + event.doubtId())
                    .build());

        } catch (Exception e) {
            log.error("Failed to process DoubtPostedEvent for doubtId={}: {}", event.doubtId(), e.getMessage(), e);
        }
    }

    @Async("notificationTaskExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onDoubtAnswered(DoubtAnsweredEvent event) {
        try {
            // Skip self-answer
            if (event.answererUserId() != null && event.answererUserId().equals(event.doubtAuthorUserId())) {
                return;
            }
            if (event.doubtAuthorUserId() == null) {
                return;
            }

            String subjectName = (event.subjectName() != null && !event.subjectName().isBlank())
                    ? event.subjectName().trim()
                    : null;
            String body = (subjectName != null)
                    ? "Your teacher has answered your doubt in " + subjectName + ". Tap to view the response."
                    : "Your teacher has answered your doubt. Tap to view the response.";

            notificationPublisher.publish(NotificationPublishRequest.builder()
                    .institutionId(event.institutionId())
                    .title("Your Doubt Has Been Answered")
                    .body(body)
                    .targetType(NotificationTargetType.USERS)
                    .targetId(event.doubtId())
                    .userIds(List.of(event.doubtAuthorUserId()))
                    .type(NotificationType.DOUBT_ANSWER)
                    .senderUserId(event.answererUserId())
                    .idempotencyKey("DOUBT_ANSWER:" + event.answerId())
                    .build());

        } catch (Exception e) {
            log.error("Failed to process DoubtAnsweredEvent for answerId={}: {}", event.answerId(), e.getMessage(), e);
        }
    }

    @Async("notificationTaskExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onAnswerApproved(AnswerApprovedEvent event) {
        try {
            String baseKey = "ANSWER_APPROVED:" + event.answerId() + ":" + event.approvedVersion();
            String subjectName = (event.subjectName() != null && !event.subjectName().isBlank())
                    ? event.subjectName().trim()
                    : null;

            // 1. Notify Answer Author (if distinct from approver)
            if (event.answerAuthorUserId() != null && !event.answerAuthorUserId().equals(event.approverUserId())) {
                notificationPublisher.publish(NotificationPublishRequest.builder()
                        .institutionId(event.institutionId())
                        .title("Your Answer was Verified")
                        .body("A teacher verified your answer.")
                        .targetType(NotificationTargetType.USERS)
                        .targetId(event.doubtId())
                        .userIds(List.of(event.answerAuthorUserId()))
                        .type(NotificationType.ANSWER_APPROVED)
                        .senderUserId(event.approverUserId())
                        .idempotencyKey(baseKey + ":author")
                        .build());
            }

            // 2. Notify Doubt Author (if distinct from approver and answer author)
            if (event.doubtAuthorUserId() != null
                    && !event.doubtAuthorUserId().equals(event.approverUserId())
                    && !event.doubtAuthorUserId().equals(event.answerAuthorUserId())) {
                String title = (subjectName != null)
                        ? "Your Doubt Has Been Accepted"
                        : "Answer Verified on Your Doubt";
                String acceptedBody = (subjectName != null)
                        ? "Your doubt in " + subjectName + " has been accepted by your teacher."
                        : "An answer to your doubt was verified by a teacher.";

                notificationPublisher.publish(NotificationPublishRequest.builder()
                        .institutionId(event.institutionId())
                        .title(title)
                        .body(acceptedBody)
                        .targetType(NotificationTargetType.USERS)
                        .targetId(event.doubtId())
                        .userIds(List.of(event.doubtAuthorUserId()))
                        .type(NotificationType.ANSWER_APPROVED)
                        .senderUserId(event.approverUserId())
                        .idempotencyKey(baseKey + ":doubt")
                        .build());
            }

        } catch (Exception e) {
            log.error("Failed to process AnswerApprovedEvent for answerId={}: {}", event.answerId(), e.getMessage(), e);
        }
    }

    @Async("notificationTaskExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onStudentAcademicChanged(StudentAcademicChangedEvent event) {
        try {
            if (event.userId() == null) return;
            if (event.actorUserId() != null && event.actorUserId().equals(event.userId())) {
                return;
            }

            String summary = (event.summary() != null && !event.summary().isBlank())
                    ? event.summary()
                    : "Your academic class or subjects have been updated.";

            notificationPublisher.publish(NotificationPublishRequest.builder()
                    .institutionId(event.institutionId())
                    .title("Academic Enrollment Updated")
                    .body(summary)
                    .targetType(NotificationTargetType.USERS)
                    .targetId(event.studentId())
                    .userIds(List.of(event.userId()))
                    .type(NotificationType.ENROLLMENT_CHANGED)
                    .senderUserId(event.actorUserId())
                    .idempotencyKey("ENROLLMENT_CHANGED:" + event.userId() + ":" + event.changeId())
                    .build());

            // Refresh topics outside DB transaction
            userTopicRefreshService.refreshTopicsForUser(event.userId());

        } catch (Exception e) {
            log.error("Failed to process StudentAcademicChangedEvent for studentId={}: {}", event.studentId(), e.getMessage(), e);
        }
    }

    @Async("notificationTaskExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onTeacherAssignment(TeacherAssignmentEvent event) {
        try {
            boolean hasAdded = event.addedSubjectNames() != null && !event.addedSubjectNames().isEmpty();
            boolean hasRemoved = event.removedSubjectNames() != null && !event.removedSubjectNames().isEmpty();

            if (!hasAdded && !hasRemoved) {
                // No-op change: send nothing
                return;
            }

            // Notify Teacher (unless actor is teacher)
            if (event.teacherUserId() != null && !Objects.equals(event.actorUserId(), event.teacherUserId())) {
                StringBuilder msg = new StringBuilder();
                if (hasAdded) {
                    msg.append("You have been assigned to: ").append(String.join(", ", event.addedSubjectNames())).append(". ");
                }
                if (hasRemoved) {
                    msg.append("You have been removed from: ").append(String.join(", ", event.removedSubjectNames())).append(".");
                }

                notificationPublisher.publish(NotificationPublishRequest.builder()
                        .institutionId(event.institutionId())
                        .title("Subject Assignment Updated")
                        .body(msg.toString().trim())
                        .targetType(NotificationTargetType.USERS)
                        .targetId(event.teacherId())
                        .userIds(List.of(event.teacherUserId()))
                        .type(NotificationType.TEACHER_ASSIGNED)
                        .senderUserId(event.actorUserId())
                        .idempotencyKey("TEACHER_ASSIGNED:" + event.teacherId() + ":" + event.changeId())
                        .build());
            }

            // Optionally notify students of newly assigned subjects via SUBJECT topic
            if (notifyStudentsOnTeacherAssign && event.addedSubjectIds() != null) {
                for (int i = 0; i < event.addedSubjectIds().size(); i++) {
                    Long subjectId = event.addedSubjectIds().get(i);
                    String subjectName = (i < event.addedSubjectNames().size()) ? event.addedSubjectNames().get(i) : "Subject";
                    notificationPublisher.publish(NotificationPublishRequest.builder()
                            .institutionId(event.institutionId())
                            .title("New Teacher Assigned")
                            .body("A teacher has been assigned to your subject: " + subjectName)
                            .targetType(NotificationTargetType.SUBJECT)
                            .targetId(subjectId)
                            .type(NotificationType.TEACHER_ASSIGNED)
                            .senderUserId(event.actorUserId())
                            .idempotencyKey("SUBJECT_TEACHER_ASSIGNED:" + subjectId + ":" + event.changeId())
                            .build());
                }
            }

            // Refresh topics for teacher
            userTopicRefreshService.refreshTopicsForUser(event.teacherUserId());

        } catch (Exception e) {
            log.error("Failed to process TeacherAssignmentEvent for teacherId={}: {}", event.teacherId(), e.getMessage(), e);
        }
    }
}
