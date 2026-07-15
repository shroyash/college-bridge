package com.college.bridge.auth.repository;

import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface TeacherRepository extends JpaRepository<Teacher, Long> {

    boolean existsByUser(User user);

    Optional<Teacher> findByUser(User user);
}

