package com.college.bridge.clazz.repository;

import com.college.bridge.auth.entity.Student;
import com.college.bridge.clazz.entity.ClassEnrollment;
import com.college.bridge.clazz.entity.ClassEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ClassEnrollmentRepository extends JpaRepository<ClassEnrollment, Long> {

    List<ClassEnrollment> findByStudent(Student student);

    List<ClassEnrollment> findByClassEntity(ClassEntity classEntity);

    boolean existsByClassEntityAndStudent(ClassEntity classEntity, Student student);
}
