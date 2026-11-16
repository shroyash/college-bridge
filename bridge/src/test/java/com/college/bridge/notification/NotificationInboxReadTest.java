package com.college.bridge.notification;

import com.college.bridge.academic.repository.AcademicLevelRepository;
import com.college.bridge.academic.repository.SubjectEnrollmentRepository;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.academic.repository.TeacherAssignmentRepository;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.repository.StudentRepository;
import com.college.bridge.auth.repository.TeacherRepository;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.auth.security.UserPrincipal;
import com.college.bridge.common.tenant.TenantContext;
import com.college.bridge.institution.entity.Institution;
import com.college.bridge.institution.repository.InstitutionRepository;
import com.college.bridge.notification.dto.NotificationInboxResponse;
import com.college.bridge.notification.dto.UnreadCountResponse;
import com.college.bridge.notification.entity.Notification;
import com.college.bridge.notification.entity.NotificationTargetType;
import com.college.bridge.notification.repository.NotificationInboxReadRepository;
import com.college.bridge.notification.repository.NotificationJobRepository;
import com.college.bridge.notification.repository.NotificationRecipientRepository;
import com.college.bridge.notification.repository.NotificationRepository;
import com.college.bridge.notification.service.NotificationService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.access.AccessDeniedException;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class NotificationInboxReadTest {

    @Mock
    private NotificationRepository notificationRepository;
    @Mock
    private NotificationJobRepository jobRepository;
    @Mock
    private NotificationRecipientRepository recipientRepository;
    @Mock
    private NotificationInboxReadRepository inboxReadRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private InstitutionRepository institutionRepository;
    @Mock
    private AcademicLevelRepository academicLevelRepository;
    @Mock
    private SubjectRepository subjectRepository;
    @Mock
    private TeacherAssignmentRepository teacherAssignmentRepository;
    @Mock
    private StudentRepository studentRepository;
    @Mock
    private TeacherRepository teacherRepository;
    @Mock
    private SubjectEnrollmentRepository enrollmentRepository;

    @InjectMocks
    private NotificationService notificationService;

    private User adminUser;
    private User studentUser;
    private User teacherUser;
    private User superAdminUser;

    private UserPrincipal adminPrincipal;
    private UserPrincipal studentPrincipal;
    private UserPrincipal teacherPrincipal;
    private UserPrincipal superAdminPrincipal;

    private final Long tenantId = 1L;

    @BeforeEach
    void setUp() {
        TenantContext.set(tenantId);

        Institution institution = Institution.builder().institutionId(tenantId).name("Test College").build();

        adminUser = User.builder()
                .userId(10L)
                .name("Admin")
                .role(UserRole.ADMIN)
                .institution(institution)
                .createdAt(LocalDateTime.of(2026, 1, 1, 0, 0))
                .build();
        adminPrincipal = new UserPrincipal(adminUser);

        studentUser = User.builder()
                .userId(20L)
                .name("Student")
                .role(UserRole.STUDENT)
                .institution(institution)
                .createdAt(LocalDateTime.of(2026, 1, 1, 0, 0))
                .build();
        studentPrincipal = new UserPrincipal(studentUser, 100L, null);

        teacherUser = User.builder()
                .userId(30L)
                .name("Teacher")
                .role(UserRole.TEACHER)
                .institution(institution)
                .createdAt(LocalDateTime.of(2026, 1, 1, 0, 0))
                .build();
        teacherPrincipal = new UserPrincipal(teacherUser, null, 200L);

        superAdminUser = User.builder()
                .userId(99L)
                .name("SuperAdmin")
                .role(UserRole.SUPER_ADMIN)
                .institution(null)
                .createdAt(LocalDateTime.of(2026, 1, 1, 0, 0))
                .build();
        superAdminPrincipal = new UserPrincipal(superAdminUser);
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
    }

    @Test
    @DisplayName("Unread count equals unread items in inbox for admin")
    void testUnreadCountForAdmin() {
        when(notificationRepository.countUnreadInbox(eq(tenantId), eq(10L), eq(-1L), eq(List.of(-1L)), any(Instant.class)))
                .thenReturn(3L);

        UnreadCountResponse response = notificationService.getUnreadCount(adminPrincipal);
        assertEquals(3L, response.getCount());
    }

    @Test
    @DisplayName("Inbox page batch loads read IDs and sets read boolean flag")
    void testInboxBatchLoadsReadState() {
        Notification n1 = Notification.builder()
                .notificationId(101L)
                .title("N1")
                .message("Message 1")
                .targetType(NotificationTargetType.INSTITUTION)
                .createdAt(Instant.now())
                .build();
        Notification n2 = Notification.builder()
                .notificationId(102L)
                .title("N2")
                .message("Message 2")
                .targetType(NotificationTargetType.INSTITUTION)
                .createdAt(Instant.now())
                .build();

        Page<Notification> mockPage = new PageImpl<>(List.of(n1, n2));
        when(notificationRepository.findUserInbox(eq(tenantId), eq(10L), eq(-1L), eq(List.of(-1L)), any(Instant.class), any()))
                .thenReturn(mockPage);

        // n1 is read, n2 is unread
        when(inboxReadRepository.findReadNotificationIds(eq(10L), eq(List.of(101L, 102L))))
                .thenReturn(Set.of(101L));

        Page<NotificationInboxResponse> result = notificationService.getUserInbox(adminPrincipal, PageRequest.of(0, 20));

        assertEquals(2, result.getContent().size());
        assertTrue(result.getContent().get(0).isRead());
        assertFalse(result.getContent().get(1).isRead());
    }

    @Test
    @DisplayName("Marking notification as read is idempotent and executes INSERT IGNORE")
    void testMarkAsReadIdempotent() {
        when(notificationRepository.isNotificationInUserInboxScope(eq(101L), eq(tenantId), eq(10L), eq(-1L), eq(List.of(-1L)), any(Instant.class)))
                .thenReturn(true);
        when(inboxReadRepository.markReadNative(101L, 10L)).thenReturn(1);

        // First tap
        assertDoesNotThrow(() -> notificationService.markAsRead(101L, adminPrincipal));

        // Second tap
        assertDoesNotThrow(() -> notificationService.markAsRead(101L, adminPrincipal));

        verify(inboxReadRepository, times(2)).markReadNative(101L, 10L);
    }

    @Test
    @DisplayName("Marking an out-of-scope notification throws 403 AccessDeniedException")
    void testMarkAsReadOutOfScopeThrows403() {
        when(notificationRepository.isNotificationInUserInboxScope(eq(999L), eq(tenantId), eq(10L), eq(-1L), eq(List.of(-1L)), any(Instant.class)))
                .thenReturn(false);

        assertThrows(AccessDeniedException.class, () -> notificationService.markAsRead(999L, adminPrincipal));
        verify(inboxReadRepository, never()).markReadNative(anyLong(), anyLong());
    }

    @Test
    @DisplayName("Super admin returns empty inbox, count 0, and markAsRead throws 403")
    void testSuperAdminEmptyAndDenied() {
        TenantContext.clear(); // SuperAdmin has no tenant context

        Page<NotificationInboxResponse> inbox = notificationService.getUserInbox(superAdminPrincipal, PageRequest.of(0, 20));
        assertTrue(inbox.isEmpty());

        UnreadCountResponse unread = notificationService.getUnreadCount(superAdminPrincipal);
        assertEquals(0L, unread.getCount());

        assertThrows(AccessDeniedException.class, () -> notificationService.markAsRead(101L, superAdminPrincipal));
    }

    @Test
    @DisplayName("New user lower bound uses user createdAt timestamp")
    void testNewUserCreatedAtLowerBound() {
        LocalDateTime newTime = LocalDateTime.of(2026, 6, 1, 12, 0);
        User newUser = User.builder()
                .userId(50L)
                .name("Newbie")
                .role(UserRole.ADMIN)
                .institution(Institution.builder().institutionId(tenantId).build())
                .createdAt(newTime)
                .build();
        UserPrincipal newPrincipal = new UserPrincipal(newUser);

        Instant expectedInstant = newTime.atZone(ZoneOffset.UTC).toInstant();

        when(notificationRepository.countUnreadInbox(eq(tenantId), eq(50L), eq(-1L), eq(List.of(-1L)), eq(expectedInstant)))
                .thenReturn(0L);

        UnreadCountResponse response = notificationService.getUnreadCount(newPrincipal);
        assertEquals(0L, response.getCount());

        verify(notificationRepository).countUnreadInbox(eq(tenantId), eq(50L), eq(-1L), eq(List.of(-1L)), eq(expectedInstant));
    }

    @Test
    @DisplayName("findReadNotificationIds returns empty set immediately when given null or empty ids")
    void testFindReadNotificationIdsEmptyHandling() {
        NotificationInboxReadRepository repo = new NotificationInboxReadRepository() {
            @Override
            public Set<Long> queryReadNotificationIds(Long userId, java.util.Collection<Long> ids) {
                return Set.of(1L, 2L);
            }
            @Override
            public int markReadNative(Long notificationId, Long userId) { return 1; }
            @Override
            public boolean existsByNotification_NotificationIdAndUser_UserId(Long notificationId, Long userId) { return true; }
            @Override
            public void flush() {}
            @Override
            public <S extends com.college.bridge.notification.entity.NotificationInboxRead> S saveAndFlush(S entity) { return null; }
            @Override
            public <S extends com.college.bridge.notification.entity.NotificationInboxRead> List<S> saveAllAndFlush(Iterable<S> entities) { return null; }
            @Override
            public void deleteAllInBatch(Iterable<com.college.bridge.notification.entity.NotificationInboxRead> entities) {}
            @Override
            public void deleteAllByIdInBatch(Iterable<Long> longs) {}
            @Override
            public void deleteAllInBatch() {}
            @Override
            public com.college.bridge.notification.entity.NotificationInboxRead getOne(Long aLong) { return null; }
            @Override
            public com.college.bridge.notification.entity.NotificationInboxRead getById(Long aLong) { return null; }
            @Override
            public com.college.bridge.notification.entity.NotificationInboxRead getReferenceById(Long aLong) { return null; }
            @Override
            public <S extends com.college.bridge.notification.entity.NotificationInboxRead> List<S> findAll(org.springframework.data.domain.Example<S> example) { return null; }
            @Override
            public <S extends com.college.bridge.notification.entity.NotificationInboxRead> List<S> findAll(org.springframework.data.domain.Example<S> example, org.springframework.data.domain.Sort sort) { return null; }
            @Override
            public <S extends com.college.bridge.notification.entity.NotificationInboxRead> List<S> saveAll(Iterable<S> entities) { return null; }
            @Override
            public List<com.college.bridge.notification.entity.NotificationInboxRead> findAll() { return null; }
            @Override
            public List<com.college.bridge.notification.entity.NotificationInboxRead> findAllById(Iterable<Long> longs) { return null; }
            @Override
            public <S extends com.college.bridge.notification.entity.NotificationInboxRead> S save(S entity) { return null; }
            @Override
            public java.util.Optional<com.college.bridge.notification.entity.NotificationInboxRead> findById(Long aLong) { return java.util.Optional.empty(); }
            @Override
            public boolean existsById(Long aLong) { return false; }
            @Override
            public long count() { return 0; }
            @Override
            public void deleteById(Long aLong) {}
            @Override
            public void delete(com.college.bridge.notification.entity.NotificationInboxRead entity) {}
            @Override
            public void deleteAllById(Iterable<? extends Long> longs) {}
            @Override
            public void deleteAll(Iterable<? extends com.college.bridge.notification.entity.NotificationInboxRead> entities) {}
            @Override
            public void deleteAll() {}
            @Override
            public List<com.college.bridge.notification.entity.NotificationInboxRead> findAll(org.springframework.data.domain.Sort sort) { return null; }
            @Override
            public Page<com.college.bridge.notification.entity.NotificationInboxRead> findAll(org.springframework.data.domain.Pageable pageable) { return null; }
            @Override
            public <S extends com.college.bridge.notification.entity.NotificationInboxRead> java.util.Optional<S> findOne(org.springframework.data.domain.Example<S> example) { return java.util.Optional.empty(); }
            @Override
            public <S extends com.college.bridge.notification.entity.NotificationInboxRead> Page<S> findAll(org.springframework.data.domain.Example<S> example, org.springframework.data.domain.Pageable pageable) { return null; }
            @Override
            public <S extends com.college.bridge.notification.entity.NotificationInboxRead> long count(org.springframework.data.domain.Example<S> example) { return 0; }
            @Override
            public <S extends com.college.bridge.notification.entity.NotificationInboxRead> boolean exists(org.springframework.data.domain.Example<S> example) { return false; }
            @Override
            public <S extends com.college.bridge.notification.entity.NotificationInboxRead, R> R findBy(org.springframework.data.domain.Example<S> example, java.util.function.Function<org.springframework.data.repository.query.FluentQuery.FetchableFluentQuery<S>, R> queryFunction) { return null; }
        };

        assertTrue(repo.findReadNotificationIds(1L, null).isEmpty());
        assertTrue(repo.findReadNotificationIds(1L, List.of()).isEmpty());
        assertEquals(2, repo.findReadNotificationIds(1L, List.of(10L, 20L)).size());
    }
}
