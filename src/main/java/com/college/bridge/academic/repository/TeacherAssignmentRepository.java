package com.college.bridge.academic.repository;

import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.entity.TeacherAssignment;
import com.college.bridge.auth.entity.Teacher;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TeacherAssignmentRepository extends JpaRepository<TeacherAssignment, Long> {

    @EntityGraph(attributePaths = {"subject", "subject.academicLevel", "subject.academicLevel.program"})
    List<TeacherAssignment> findByTeacherTeacherId(Long teacherId);

    @EntityGraph(attributePaths = {"subject", "subject.academicLevel", "subject.academicLevel.program"})
    List<TeacherAssignment> findByTeacher_TeacherId(Long teacherId);

    boolean existsByTeacherAndSubject(Teacher teacher, Subject subject);

    boolean existsByTeacher_TeacherIdAndSubject_SubjectId(Long teacherId, Long subjectId);

    boolean existsByTeacher_TeacherIdAndSubject_AcademicLevel_LevelId(Long teacherId, Long levelId);

    void deleteByTeacherTeacherId(Long teacherId);
}