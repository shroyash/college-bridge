package com.college.bridge.clazz.repository;

import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.clazz.entity.ClassEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ClassRepository extends JpaRepository<ClassEntity, Long> {

    List<ClassEntity> findByTeacher(Teacher teacher);

    List<ClassEntity> findByTeacherIsNull();
}
