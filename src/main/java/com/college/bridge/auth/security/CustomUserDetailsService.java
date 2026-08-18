package com.college.bridge.auth.security;

import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.repository.StudentRepository;
import com.college.bridge.auth.repository.TeacherRepository;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.institution.entity.Institution;
import com.college.bridge.institution.repository.InstitutionRepository;
import org.springframework.context.annotation.Primary;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Primary
@Transactional(readOnly = true)
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final InstitutionRepository institutionRepository;

    public CustomUserDetailsService(
            UserRepository userRepository,
            StudentRepository studentRepository,
            TeacherRepository teacherRepository,
            InstitutionRepository institutionRepository
    ) {
        this.userRepository = userRepository;
        this.studentRepository = studentRepository;
        this.teacherRepository = teacherRepository;
        this.institutionRepository = institutionRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User user;

        if (username != null && username.contains(":")) {
            String[] parts = username.split(":", 2);
            String institutionCode = parts[0];
            String email = parts[1];

            Institution institution = institutionRepository.findByCode(institutionCode)
                    .orElseThrow(() -> new UsernameNotFoundException("Institution not found with code: " + institutionCode));

            user = userRepository.findByInstitution_InstitutionIdAndEmail(institution.getInstitutionId(), email)
                    .orElseThrow(() -> new UsernameNotFoundException("User not found with email: " + email + " in institution: " + institutionCode));
        } else {
            user = userRepository.findByEmail(username)
                    .orElseThrow(() -> new UsernameNotFoundException("User not found with email: " + username));
        }

        return buildUserPrincipal(user);
    }

    public UserDetails loadUserByInstitutionIdAndEmail(Long institutionId, String email) throws UsernameNotFoundException {
        User user = userRepository.findByInstitution_InstitutionIdAndEmail(institutionId, email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found with email: " + email + " for institution: " + institutionId));

        return buildUserPrincipal(user);
    }

    private UserPrincipal buildUserPrincipal(User user) {
        Long studentId = null;
        Long teacherId = null;

        if (user.getRole() == UserRole.STUDENT) {
            studentId = studentRepository.findByUser_UserId(user.getUserId())
                    .map(Student::getStudentId)
                    .orElse(null);
        } else if (user.getRole() == UserRole.TEACHER) {
            teacherId = teacherRepository.findByUser_UserId(user.getUserId())
                    .map(Teacher::getTeacherId)
                    .orElse(null);
        }

        return new UserPrincipal(user, studentId, teacherId);
    }
}