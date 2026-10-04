package com.college.bridge.notification.fcm;

import com.college.bridge.academic.entity.AcademicLevel;
import com.college.bridge.academic.entity.ClassStatus;
import com.college.bridge.academic.entity.SubjectEnrollment;
import com.college.bridge.academic.entity.TeacherAssignment;
import com.college.bridge.academic.repository.SubjectEnrollmentRepository;
import com.college.bridge.academic.repository.TeacherAssignmentRepository;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.repository.StudentRepository;
import com.college.bridge.auth.repository.TeacherRepository;
import com.college.bridge.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

@Component
@RequiredArgsConstructor
public class DesiredTopicResolver {

    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final SubjectEnrollmentRepository enrollmentRepository;
    private final TeacherAssignmentRepository teacherAssignmentRepository;

    @Transactional(readOnly = true)
    public Optional<Set<String>> resolve(Long userId) {
        User user = userRepository.findById(userId).orElse(null);
        if (user == null || user.getInstitution() == null) {
            return Optional.empty();
        }
        Long tenantId = user.getInstitution().getInstitutionId();

        Set<String> topics = new HashSet<>();
        topics.add("tenant_" + tenantId + "_all");

        if (user.getRole() == UserRole.ADMIN) {
            topics.add("tenant_" + tenantId + "_admins");

        } else if (user.getRole() == UserRole.TEACHER) {
            topics.add("tenant_" + tenantId + "_teachers");
            teacherRepository.findByUser_UserId(user.getUserId()).ifPresent(teacher -> {
                List<TeacherAssignment> assignments = teacherAssignmentRepository
                        .findActiveByTeacherIdAndInstitutionId(teacher.getTeacherId(), tenantId);
                for (TeacherAssignment ta : assignments) {
                    if (ta.getSubject() != null && !ta.getSubject().isDeleted()) {
                        topics.add("tenant_" + tenantId + "_subject_" + ta.getSubject().getSubjectId());
                        if (ta.getSubject().getAcademicLevel() != null
                                && !ta.getSubject().getAcademicLevel().isDeleted()) {
                            topics.add("tenant_" + tenantId + "_class_"
                                    + ta.getSubject().getAcademicLevel().getLevelId());
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
                List<SubjectEnrollment> enrollments = enrollmentRepository
                        .findActiveByStudentIdAndInstitutionId(student.getStudentId(), tenantId);
                for (SubjectEnrollment se : enrollments) {
                    if (se.getStatus() == ClassStatus.ACTIVE && !se.getSubject().isDeleted()) {
                        topics.add("tenant_" + tenantId + "_subject_" + se.getSubject().getSubjectId());
                    }
                }
            });
        }
        return Optional.of(topics);
    }
}