package com.college.bridge.notification.service;

import com.college.bridge.academic.entity.AcademicLevel;
import com.college.bridge.academic.entity.ClassStatus;
import com.college.bridge.academic.entity.SubjectEnrollment;
import com.college.bridge.academic.entity.TeacherAssignment;
import com.college.bridge.academic.repository.SubjectEnrollmentRepository;
import com.college.bridge.academic.repository.TeacherAssignmentRepository;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.repository.StudentRepository;
import com.college.bridge.auth.repository.TeacherRepository;
import com.college.bridge.notification.entity.DeviceTopicSubscription;
import com.college.bridge.notification.entity.FcmDevice;
import com.college.bridge.notification.fcm.FcmNotificationService;
import com.college.bridge.notification.repository.DeviceTopicSubscriptionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationTopicSyncService {

    private final DeviceTopicSubscriptionRepository subscriptionRepository;
    private final FcmNotificationService fcmService;
    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final SubjectEnrollmentRepository enrollmentRepository;
    private final TeacherAssignmentRepository teacherAssignmentRepository;

    @Transactional
    public void syncDeviceTopics(FcmDevice device, User user) {
        Long tenantId = user.getInstitution() != null ? user.getInstitution().getInstitutionId() : null;
        if (tenantId == null) {
            return;
        }

        Set<String> desiredTopics = computeDesiredTopics(user, tenantId);
        List<DeviceTopicSubscription> currentSubs = subscriptionRepository.findByDevice_DeviceId(device.getDeviceId());
        Set<String> currentTopics = currentSubs.stream().map(DeviceTopicSubscription::getTopic).collect(Collectors.toSet());

        Set<String> toAdd = new HashSet<>(desiredTopics);
        toAdd.removeAll(currentTopics);

        Set<String> toRemove = new HashSet<>(currentTopics);
        toRemove.removeAll(desiredTopics);

        String token = device.getFcmToken();

        // 1. Unsubscribe from removed topics
        for (String topic : toRemove) {
            fcmService.unsubscribeTokensFromTopic(List.of(token), topic);
        }
        if (!toRemove.isEmpty()) {
            subscriptionRepository.deleteByDevice_DeviceIdAndTopicIn(device.getDeviceId(), toRemove);
        }

        // 2. Subscribe to added topics
        for (String topic : toAdd) {
            fcmService.subscribeTokensToTopic(List.of(token), topic);
            subscriptionRepository.save(DeviceTopicSubscription.builder()
                    .device(device)
                    .topic(topic)
                    .createdAt(Instant.now())
                    .build());
        }
    }

    @Transactional
    public void unsubscribeAllFromDevice(FcmDevice device) {
        List<DeviceTopicSubscription> currentSubs = subscriptionRepository.findByDevice_DeviceId(device.getDeviceId());
        if (currentSubs.isEmpty()) {
            return;
        }

        String token = device.getFcmToken();
        for (DeviceTopicSubscription sub : currentSubs) {
            fcmService.unsubscribeTokensFromTopic(List.of(token), sub.getTopic());
        }

        subscriptionRepository.deleteByDeviceId(device.getDeviceId());
    }

    private Set<String> computeDesiredTopics(User user, Long tenantId) {
        Set<String> topics = new HashSet<>();
        topics.add("tenant_" + tenantId + "_all");

        if (user.getRole() == UserRole.ADMIN) {
            topics.add("tenant_" + tenantId + "_admins");
        } else if (user.getRole() == UserRole.TEACHER) {
            topics.add("tenant_" + tenantId + "_teachers");
            teacherRepository.findByUser_UserId(user.getUserId()).ifPresent(teacher -> {
                List<TeacherAssignment> assignments = teacherAssignmentRepository.findActiveByTeacherIdAndInstitutionId(teacher.getTeacherId(), tenantId);
                for (TeacherAssignment ta : assignments) {
                    if (ta.getSubject() != null && !ta.getSubject().isDeleted()) {
                        topics.add("tenant_" + tenantId + "_subject_" + ta.getSubject().getSubjectId());
                        if (ta.getSubject().getAcademicLevel() != null && !ta.getSubject().getAcademicLevel().isDeleted()) {
                            topics.add("tenant_" + tenantId + "_class_" + ta.getSubject().getAcademicLevel().getLevelId());
                        }
                    }
                }
            });
        } else if (user.getRole() == UserRole.STUDENT) {
            studentRepository.findByUser_UserId(user.getUserId()).ifPresent(student -> {
                AcademicLevel level = student.getAcademicLevel();
                if (level != null && !level.isDeleted()) {
                    topics.add("tenant_" + tenantId + "_class_" + level.getLevelId());
                }
                List<SubjectEnrollment> enrollments = enrollmentRepository.findActiveByStudentIdAndInstitutionId(student.getStudentId(), tenantId);
                for (SubjectEnrollment se : enrollments) {
                    if (se.getStatus() == ClassStatus.ACTIVE && !se.getSubject().isDeleted()) {
                        topics.add("tenant_" + tenantId + "_subject_" + se.getSubject().getSubjectId());
                    }
                }
            });
        }
        return topics;
    }
}
