package com.college.bridge.auth.repository;

import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.entity.User;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface StudentRepository extends JpaRepository<Student, Long> {
    Optional<Student> findByUser(User user);

    @EntityGraph(attributePaths = {"academicClass", "user"})
    Optional<Student> findByUser_UserId(Long userId);

    @EntityGraph(attributePaths = {"academicClass", "user"})
    Optional<Student> findByStudentId(Long studentId);

    List<Student> findByUser_UserIdIn(List<Long> userIds);
}
