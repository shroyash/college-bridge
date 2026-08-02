package com.college.bridge.academic.service;

import com.college.bridge.academic.dto.SubjectResponse;
import com.college.bridge.academic.entity.AcademicClass;
import com.college.bridge.academic.entity.Faculty;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.auth.entity.Student;
import com.college.bridge.auth.repository.StudentRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SubjectService {

    private final SubjectRepository subjectRepository;
    private final StudentRepository studentRepository;

    public List<SubjectResponse> getSubjects(Faculty faculty, Integer semester) {
        return subjectRepository.findByFacultyAndSemester(faculty, semester)
                .stream()
                .map(SubjectResponse::from)
                .toList();
    }

    public List<SubjectResponse> getSubjectsForStudent(Long studentId) {
        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new EntityNotFoundException("Student not found: " + studentId));

        AcademicClass academicClass = student.getAcademicClass();

        return subjectRepository.findByFacultyAndSemester(
                        academicClass.getFaculty(),
                        academicClass.getSemester()
                ).stream()
                .map(SubjectResponse::from)
                .toList();
    }
}