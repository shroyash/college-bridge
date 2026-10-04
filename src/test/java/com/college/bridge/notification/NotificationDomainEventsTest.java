package com.college.bridge.notification;

import com.college.bridge.academic.entity.ClassStatus;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.entity.SubjectEnrollment;
import com.college.bridge.academic.entity.TeacherAssignment;
import com.college.bridge.academic.repository.SubjectEnrollmentRepository;
import com.college.bridge.academic.repository.TeacherAssignmentRepository;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.entity.User;
import com.college.bridge.institution.entity.Institution;
import com.college.bridge.notification.dto.NotificationPublishRequest;
import com.college.bridge.notification.entity.NotificationTargetType;
import com.college.bridge.notification.entity.NotificationType;
import com.college.bridge.notification.event.*;
import com.college.bridge.notification.listener.NotificationDomainEventListener;
import com.college.bridge.notification.service.NotificationPublisher;
import com.college.bridge.notification.service.UserTopicRefreshService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class NotificationDomainEventsTest {

    @Mock
    private NotificationPublisher notificationPublisher;

    @Mock
    private UserTopicRefreshService userTopicRefreshService;

    @Mock
    private TeacherAssignmentRepository teacherAssignmentRepository;

    @Mock
    private SubjectEnrollmentRepository subjectEnrollmentRepository;

    @InjectMocks
    private NotificationDomainEventListener listener;

    private final Long tenantId = 1L;
    private Institution institution;

    @BeforeEach
    void setUp() {
        institution = Institution.builder().institutionId(tenantId).name("Test College").build();
        ReflectionTestUtils.setField(listener, "notifyClassmatesOnDoubt", true);
        ReflectionTestUtils.setField(listener, "notifyStudentsOnTeacherAssign", false);
    }

    @Test
    @DisplayName("Doubt posted notifies subject teachers and enrolled classmates, excluding author")
    void testStudentDoubtNotifiesTeachersAndClassmatesExcludingAuthor() {
        Long subjectId = 100L;
        Long authorUserId = 20L;

        // Teacher
        User teacherUser = User.builder().userId(30L).institution(institution).build();
        Teacher teacher = Teacher.builder().teacherId(1L).user(teacherUser).build();
        TeacherAssignment ta = TeacherAssignment.builder().teacher(teacher).build();
        when(teacherAssignmentRepository.findBySubject_SubjectIdInAndTenantId(List.of(subjectId), tenantId))
                .thenReturn(List.of(ta));

        // Classmate and Author
        User classmateUser = User.builder().userId(21L).institution(institution).build();
        Student classmate = Student.builder().studentId(2L).user(classmateUser).build();
        SubjectEnrollment seClassmate = SubjectEnrollment.builder().student(classmate).status(ClassStatus.ACTIVE).build();

        User authorUser = User.builder().userId(authorUserId).institution(institution).build();
        Student authorStudent = Student.builder().studentId(1L).user(authorUser).build();
        SubjectEnrollment seAuthor = SubjectEnrollment.builder().student(authorStudent).status(ClassStatus.ACTIVE).build();

        when(subjectEnrollmentRepository.findBySubject_SubjectId(subjectId))
                .thenReturn(List.of(seClassmate, seAuthor));

        DoubtPostedEvent event = new DoubtPostedEvent(500L, subjectId, authorUserId, authorUserId, tenantId, "What is polymorphism?");
        listener.onDoubtPosted(event);

        ArgumentCaptor<NotificationPublishRequest> captor = ArgumentCaptor.forClass(NotificationPublishRequest.class);
        verify(notificationPublisher).publish(captor.capture());

        NotificationPublishRequest req = captor.getValue();
        assertEquals(NotificationTargetType.USERS, req.getTargetType());
        assertEquals(NotificationType.DOUBT_POSTED, req.getType());
        assertEquals(500L, req.getTargetId());
        // Contains teacher (30L) and classmate (21L), but NOT author (20L)
        assertTrue(req.getUserIds().contains(30L));
        assertTrue(req.getUserIds().contains(21L));
        assertFalse(req.getUserIds().contains(20L));
        assertEquals(2, req.getUserIds().size());
        assertEquals("DOUBT_POSTED:500", req.getIdempotencyKey());
    }

    @Test
    @DisplayName("With notify-classmates-on-doubt=false, only teachers are notified")
    void testDoubtWithNotifyClassmatesFalse() {
        ReflectionTestUtils.setField(listener, "notifyClassmatesOnDoubt", false);

        Long subjectId = 100L;
        Long authorUserId = 20L;

        User teacherUser = User.builder().userId(30L).institution(institution).build();
        Teacher teacher = Teacher.builder().teacherId(1L).user(teacherUser).build();
        TeacherAssignment ta = TeacherAssignment.builder().teacher(teacher).build();
        when(teacherAssignmentRepository.findBySubject_SubjectIdInAndTenantId(List.of(subjectId), tenantId))
                .thenReturn(List.of(ta));

        DoubtPostedEvent event = new DoubtPostedEvent(501L, subjectId, authorUserId, authorUserId, tenantId, "Test");
        listener.onDoubtPosted(event);

        ArgumentCaptor<NotificationPublishRequest> captor = ArgumentCaptor.forClass(NotificationPublishRequest.class);
        verify(notificationPublisher).publish(captor.capture());

        NotificationPublishRequest req = captor.getValue();
        assertEquals(List.of(30L), req.getUserIds());
        verify(subjectEnrollmentRepository, never()).findBySubject_SubjectId(anyLong());
    }

    @Test
    @DisplayName("Doubt answer notifies doubt author, but self-answer sends nothing")
    void testDoubtAnsweredAndSelfAnswer() {
        // Answer by someone else -> notifies doubt author
        DoubtAnsweredEvent event1 = new DoubtAnsweredEvent(500L, 600L, 30L, 20L, tenantId, "Here is how it works.");
        listener.onDoubtAnswered(event1);

        ArgumentCaptor<NotificationPublishRequest> captor = ArgumentCaptor.forClass(NotificationPublishRequest.class);
        verify(notificationPublisher).publish(captor.capture());
        assertEquals(List.of(20L), captor.getValue().getUserIds());
        assertEquals(NotificationType.DOUBT_ANSWER, captor.getValue().getType());
        assertEquals("DOUBT_ANSWER:600", captor.getValue().getIdempotencyKey());

        // Self-answer: answerer == doubt author -> sends nothing
        DoubtAnsweredEvent selfAnswer = new DoubtAnsweredEvent(500L, 601L, 20L, 20L, tenantId, "Self answer");
        listener.onDoubtAnswered(selfAnswer);

        verify(notificationPublisher, times(1)).publish(any()); // No second call
    }

    @Test
    @DisplayName("Answer approval notifies answer author and doubt author once each, skipping approver")
    void testAnswerApprovalNotifiesAuthorsSkippingApprover() {
        Long approverId = 30L;
        Long answerAuthorId = 25L;
        Long doubtAuthorId = 20L;
        long version = 1700000000000L;

        AnswerApprovedEvent event = new AnswerApprovedEvent(500L, 600L, approverId, answerAuthorId, doubtAuthorId, tenantId, version);
        listener.onAnswerApproved(event);

        ArgumentCaptor<NotificationPublishRequest> captor = ArgumentCaptor.forClass(NotificationPublishRequest.class);
        verify(notificationPublisher, times(2)).publish(captor.capture());

        List<NotificationPublishRequest> requests = captor.getAllValues();
        assertEquals(List.of(answerAuthorId), requests.get(0).getUserIds());
        assertEquals("Your Answer was Verified", requests.get(0).getTitle());
        assertEquals("ANSWER_APPROVED:600:" + version + ":author", requests.get(0).getIdempotencyKey());

        assertEquals(List.of(doubtAuthorId), requests.get(1).getUserIds());
        assertEquals("Answer Verified on Your Doubt", requests.get(1).getTitle());
        assertEquals("ANSWER_APPROVED:600:" + version + ":doubt", requests.get(1).getIdempotencyKey());
    }

    @Test
    @DisplayName("Student academic change notifies student and triggers topic refresh")
    void testStudentAcademicChange() {
        StudentAcademicChangedEvent event = new StudentAcademicChangedEvent(
                1L, 20L, tenantId, 10L, "Class updated to BCA 5th Sem", "change-123"
        );
        listener.onStudentAcademicChanged(event);

        ArgumentCaptor<NotificationPublishRequest> captor = ArgumentCaptor.forClass(NotificationPublishRequest.class);
        verify(notificationPublisher).publish(captor.capture());

        assertEquals(List.of(20L), captor.getValue().getUserIds());
        assertEquals(NotificationType.ENROLLMENT_CHANGED, captor.getValue().getType());
        assertEquals("ENROLLMENT_CHANGED:20:change-123", captor.getValue().getIdempotencyKey());
        verify(userTopicRefreshService).refreshTopicsForUser(20L);
    }

    @Test
    @DisplayName("Teacher assignment notifies teacher with distinct wording for added vs removed subjects")
    void testTeacherAssignmentWording() {
        TeacherAssignmentEvent event = new TeacherAssignmentEvent(
                5L, 30L, tenantId, 10L,
                List.of("Data Structures"),
                List.of("Operating Systems"),
                List.of(101L),
                List.of(102L),
                "change-456"
        );
        listener.onTeacherAssignment(event);

        ArgumentCaptor<NotificationPublishRequest> captor = ArgumentCaptor.forClass(NotificationPublishRequest.class);
        verify(notificationPublisher).publish(captor.capture());

        NotificationPublishRequest req = captor.getValue();
        assertEquals(List.of(30L), req.getUserIds());
        assertTrue(req.getBody().contains("You have been assigned to: Data Structures."));
        assertTrue(req.getBody().contains("You have been removed from: Operating Systems."));
        assertEquals("TEACHER_ASSIGNED:5:change-456", req.getIdempotencyKey());
        verify(userTopicRefreshService).refreshTopicsForUser(30L);
    }

    @Test
    @DisplayName("No-op teacher assignment change sends nothing")
    void testNoOpTeacherAssignmentSendsNothing() {
        TeacherAssignmentEvent noOp = new TeacherAssignmentEvent(
                5L, 30L, tenantId, 10L,
                List.of(), List.of(), List.of(), List.of(), "no-op"
        );
        listener.onTeacherAssignment(noOp);

        verify(notificationPublisher, never()).publish(any());
        verify(userTopicRefreshService, never()).refreshTopicsForUser(anyLong());
    }

    @Test
    @DisplayName("Listener failure logs error and does not throw exception to caller")
    void testListenerFailureDoesNotBreakCaller() {
        doThrow(new RuntimeException("Database error in publisher"))
                .when(notificationPublisher).publish(any());

        DoubtAnsweredEvent event = new DoubtAnsweredEvent(500L, 600L, 30L, 20L, tenantId, "Hello");

        assertDoesNotThrow(() -> listener.onDoubtAnswered(event));
    }

    @Test
    @DisplayName("Tenant isolation: students from a different institution are never notified")
    void testTenantIsolationDifferentInstitutionNotNotified() {
        Long subjectId = 100L;
        Long authorUserId = 20L;

        // Student enrolled in subject, but belonging to a DIFFERENT institution (institutionId = 999L)
        Institution otherInstitution = Institution.builder().institutionId(999L).name("Other College").build();
        User foreignUser = User.builder().userId(77L).institution(otherInstitution).build();
        Student foreignStudent = Student.builder().studentId(7L).user(foreignUser).build();
        SubjectEnrollment seForeign = SubjectEnrollment.builder().student(foreignStudent).status(ClassStatus.ACTIVE).build();

        when(teacherAssignmentRepository.findBySubject_SubjectIdInAndTenantId(List.of(subjectId), tenantId))
                .thenReturn(List.of());
        when(subjectEnrollmentRepository.findBySubject_SubjectId(subjectId))
                .thenReturn(List.of(seForeign));

        DoubtPostedEvent event = new DoubtPostedEvent(500L, subjectId, authorUserId, authorUserId, tenantId, "Test Isolation");
        listener.onDoubtPosted(event);

        // Foreign user was excluded, audience is empty -> nothing published
        verify(notificationPublisher, never()).publish(any());
    }

    @Test
    @DisplayName("Deduplication: a user appearing in multiple roles is only notified once")
    void testUserInMultipleRolesDeduplicated() {
        Long subjectId = 100L;
        Long authorUserId = 20L;
        Long dualUserId = 30L;

        // User is a teacher of the subject
        User dualUser = User.builder().userId(dualUserId).institution(institution).build();
        Teacher teacher = Teacher.builder().teacherId(1L).user(dualUser).build();
        TeacherAssignment ta = TeacherAssignment.builder().teacher(teacher).build();
        when(teacherAssignmentRepository.findBySubject_SubjectIdInAndTenantId(List.of(subjectId), tenantId))
                .thenReturn(List.of(ta));

        // And user is also enrolled as a student in the same subject
        Student student = Student.builder().studentId(2L).user(dualUser).build();
        SubjectEnrollment se = SubjectEnrollment.builder().student(student).status(ClassStatus.ACTIVE).build();
        when(subjectEnrollmentRepository.findBySubject_SubjectId(subjectId))
                .thenReturn(List.of(se));

        DoubtPostedEvent event = new DoubtPostedEvent(500L, subjectId, authorUserId, authorUserId, tenantId, "Deduplication Test");
        listener.onDoubtPosted(event);

        ArgumentCaptor<NotificationPublishRequest> captor = ArgumentCaptor.forClass(NotificationPublishRequest.class);
        verify(notificationPublisher).publish(captor.capture());

        NotificationPublishRequest req = captor.getValue();
        assertEquals(1, req.getUserIds().size());
        assertEquals(List.of(dualUserId), req.getUserIds());
    }
}
