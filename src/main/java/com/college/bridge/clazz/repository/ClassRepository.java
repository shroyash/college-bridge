package com.college.bridge.clazz.repository;

import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.clazz.entity.ClassEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ClassRepository extends JpaRepository<ClassEntity, Long> {

    List<ClassEntity> findByInstitution_InstitutionIdAndTeacher(Long institutionId, Teacher teacher);

    List<ClassEntity> findByInstitution_InstitutionIdAndTeacherIsNull(Long institutionId);

    List<ClassEntity> findByInstitution_InstitutionIdAndFacultyAndSemester(Long institutionId, String faculty, Integer semester);

    List<ClassEntity> findByInstitution_InstitutionId(Long institutionId);

    Optional<ClassEntity> findByClassIdAndInstitution_InstitutionId(Long classId, Long institutionId);
}
