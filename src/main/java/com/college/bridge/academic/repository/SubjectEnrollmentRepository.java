package com.college.bridge.academic.repository;

import com.college.bridge.academic.entity.SubjectEnrollment;
import com.college.bridge.auth.entity.Student;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SubjectEnrollmentRepository extends JpaRepository<SubjectEnrollment, Long> {

    List<SubjectEnrollment> findByStudent(Student student);
}
