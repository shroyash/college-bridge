package com.college.bridge.auth.service;

import com.college.bridge.auth.dto.CreateTeacherRequest;
import com.college.bridge.auth.dto.TeacherResponse;
import com.college.bridge.auth.dto.UpdateTeacherRequest;
import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.mapper.TeacherMapper;
import com.college.bridge.auth.repository.TeacherRepository;
import com.college.bridge.auth.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;


@Service
@RequiredArgsConstructor
@Transactional
public class TeacherService {

    private final TeacherRepository teacherRepository;
    private final UserRepository userRepository;
    private final TeacherMapper teacherMapper;
    private final PasswordEncoder passwordEncoder;


    public TeacherResponse createTeacher(CreateTeacherRequest request) {

        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Email is already registered.");
        }

        User user = teacherMapper.toUser(request);

        user.setRole(UserRole.TEACHER);

        user.setPasswordHash(
                passwordEncoder.encode(request.getPassword())
        );

        Teacher teacher = teacherMapper.toTeacher(user);

        teacherRepository.save(teacher);

        return teacherMapper.toResponse(teacher);
    }


    @Transactional(readOnly = true)
    public TeacherResponse getTeacher(Long teacherId) {

        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() ->
                        new EntityNotFoundException("Teacher not found."));

        return teacherMapper.toResponse(teacher);
    }


    @Transactional(readOnly = true)
    public Page<TeacherResponse> getTeachers(Pageable pageable) {

        return teacherRepository.findAll(pageable)
                .map(teacherMapper::toResponse);
    }


    public TeacherResponse updateTeacher(
            Long teacherId,
            UpdateTeacherRequest request
    ) {

        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() ->
                        new EntityNotFoundException("Teacher not found."));

        User user = teacher.getUser();

        if (!user.getEmail().equals(request.getEmail())
                && userRepository.existsByEmail(request.getEmail())) {

            throw new IllegalArgumentException(
                    "Email is already registered."
            );
        }

        teacherMapper.updateUser(request, user);

        return teacherMapper.toResponse(teacher);
    }


    public void deleteTeacher(Long teacherId) {

        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() ->
                        new EntityNotFoundException("Teacher not found."));

        teacherRepository.delete(teacher);
    }

}