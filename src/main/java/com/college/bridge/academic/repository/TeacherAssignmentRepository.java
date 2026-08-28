package com.college.bridge.academic.repository;

import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.entity.TeacherAssignment;
import com.college.bridge.auth.entity.Teacher;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TeacherAssignmentRepository
        extends JpaRepository<TeacherAssignment, Long> {

    List<TeacherAssignment> findByTeacherTeacherId(Long teacherId);

    boolean existsByTeacherAndSubject(
            Teacher teacher,
            Subject subject
    );

    boolean existsByTeacher_TeacherIdAndSubject_FacultyAndSubject_Semester(
            Long teacherId,
            String faculty,
            Integer semester
    );

    void deleteByTeacherTeacherId(Long teacherId);

}