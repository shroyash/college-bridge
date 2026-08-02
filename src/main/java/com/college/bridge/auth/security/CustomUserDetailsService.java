package com.college.bridge.auth.security;

import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.repository.TeacherRepository;
import com.college.bridge.auth.repository.UserRepository;
import com.college.bridge.auth.repository.StudentRepository; // NEW
import org.springframework.context.annotation.Primary;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
@Primary
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;

    public CustomUserDetailsService(UserRepository userRepository,
                                    StudentRepository studentRepository, TeacherRepository teacherRepository) { // NEW param
        this.userRepository = userRepository;
        this.studentRepository = studentRepository;
        this.teacherRepository = teacherRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User user = userRepository.findByEmail(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found with email: " + username));

        Long studentId = null;
        Long teacherId = null;

        if (user.getRole() == UserRole.STUDENT) {
            studentId = studentRepository.findByUser_UserId(user.getUserId())
                    .map(Student::getStudentId)
                    .orElse(null);
        }
         else if (user.getRole() == UserRole.TEACHER) {
             teacherId = teacherRepository.findByUser_UserId(user.getUserId())
                     .map(Teacher::getTeacherId)
                     .orElse(null);
         }

        return new CustomUserDetails(user, studentId, teacherId);
    }
}