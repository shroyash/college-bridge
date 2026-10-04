package com.college.bridge.notification;

import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.repository.TeacherAssignmentRepository;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.tenant.TenantContext;
import com.college.bridge.doubt.entity.Doubt;
import com.college.bridge.doubt.entity.DoubtAnswer;
import com.college.bridge.doubt.mapper.DoubtAnswerMapper;
import com.college.bridge.doubt.repository.DoubtAnswerRepository;
import com.college.bridge.doubt.repository.DoubtRepository;
import com.college.bridge.doubt.service.DoubtAnswerService;
import com.college.bridge.notification.event.AnswerApprovedEvent;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class DoubtAnswerApprovalTest {

    @Mock
    private DoubtRepository doubtRepository;
    @Mock
    private DoubtAnswerRepository doubtAnswerRepository;
    @Mock
    private com.college.bridge.auth.repository.UserRepository userRepository;
    @Mock
    private TeacherAssignmentRepository teacherAssignmentRepository;
    @Mock
    private DoubtAnswerMapper doubtAnswerMapper;
    @Mock
    private ApplicationEventPublisher eventPublisher;

    @InjectMocks
    private DoubtAnswerService doubtAnswerService;

    private final Long tenantId = 1L;
    private User teacherUser;
    private UserPrincipal teacherPrincipal;
    private DoubtAnswer answer;

    @BeforeEach
    void setUp() {
        TenantContext.set(tenantId);

        teacherUser = User.builder().userId(10L).build();
        Teacher teacher = Teacher.builder().teacherId(1L).user(teacherUser).build();
        teacherPrincipal = new UserPrincipal(teacherUser, null, 1L);

        User doubtAuthorUser = User.builder().userId(20L).build();
        Student doubtAuthor = Student.builder().studentId(2L).user(doubtAuthorUser).build();

        Subject subject = Subject.builder().subjectId(100L).build();
        Doubt doubt = Doubt.builder().doubtId(500L).subject(subject).student(doubtAuthor).build();

        User answerAuthor = User.builder().userId(30L).build();
        answer = DoubtAnswer.builder()
                .answerId(600L)
                .doubt(doubt)
                .answeredBy(answerAuthor)
                .isVerified(false)
                .build();
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
    }

    @Test
    @DisplayName("Approve answer on false -> true publishes event; re-saving approved answer publishes nothing; un-approving and re-approving publishes again")
    void testApproveUnapproveApproveTransitions() {
        when(doubtAnswerRepository.findByIdAndDoubtAndTenant(600L, 500L, tenantId))
                .thenReturn(Optional.of(answer));
        when(teacherAssignmentRepository.existsByTeacherSubjectAndTenant(1L, 100L, tenantId))
                .thenReturn(true);

        // 1. Initial approval: false -> true -> publishes event
        doubtAnswerService.verifyAnswer(500L, 600L, teacherPrincipal);
        assertTrue(answer.isVerified());

        ArgumentCaptor<AnswerApprovedEvent> captor = ArgumentCaptor.forClass(AnswerApprovedEvent.class);
        verify(eventPublisher, times(1)).publishEvent(captor.capture());
        AnswerApprovedEvent event1 = captor.getValue();
        assertEquals(600L, event1.answerId());
        assertEquals(500L, event1.doubtId());
        assertEquals(10L, event1.approverUserId());
        assertEquals(30L, event1.answerAuthorUserId());
        assertEquals(20L, event1.doubtAuthorUserId());

        // 2. Re-saving when already verified: true -> true -> sends NOTHING
        doubtAnswerService.verifyAnswer(500L, 600L, teacherPrincipal);
        verify(eventPublisher, times(1)).publishEvent(any(AnswerApprovedEvent.class)); // Still only 1 call

        // 3. Un-approve manually (e.g. status reset)
        answer.setVerified(false);

        // 4. Re-approve: false -> true -> publishes event again with fresh approvedVersion
        doubtAnswerService.verifyAnswer(500L, 600L, teacherPrincipal);
        assertTrue(answer.isVerified());
        verify(eventPublisher, times(2)).publishEvent(any(AnswerApprovedEvent.class));
    }
}
