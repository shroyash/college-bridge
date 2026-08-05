package com.college.bridge.academic.service;



import com.college.bridge.academic.dto.AssignTeacherSubjectsRequest;
import com.college.bridge.academic.dto.TeacherAssignmentResponse;
import com.college.bridge.academic.entity.Subject;
import com.college.bridge.academic.entity.TeacherAssignment;
import com.college.bridge.academic.exception.TeacherAssignmentAlreadyExistsException;
import com.college.bridge.academic.mapper.TeacherAssignmentMapper;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.academic.repository.TeacherAssignmentRepository;
import com.college.bridge.auth.entity.Teacher;
import com.college.bridge.auth.repository.TeacherRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class TeacherAssignmentService {

    private final TeacherRepository teacherRepository;
    private final SubjectRepository subjectRepository;
    private final TeacherAssignmentRepository teacherAssignmentRepository;
    private final TeacherAssignmentMapper mapper;

    @Transactional
    public List<TeacherAssignmentResponse> assignSubjects(
            Long teacherId,
            AssignTeacherSubjectsRequest request
    ) {

        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() ->
                        new EntityNotFoundException("Teacher not found."));


        List<Long> subjectIds = request.getSubjectIds()
                .stream()
                .distinct()
                .toList();

        List<Subject> subjects = subjectRepository.findAllById(subjectIds);


        if (subjects.size() != subjectIds.size()) {
            throw new EntityNotFoundException(
                    "One or more selected subjects do not exist."
            );
        }

        List<TeacherAssignment> existingAssignments =
                teacherAssignmentRepository.findByTeacherTeacherId(teacherId);

        Set<Long> assignedSubjectIds = existingAssignments.stream()
                .map(assignment -> assignment.getSubject().getSubjectId())
                .collect(Collectors.toSet());

        List<String> duplicateSubjects = subjects.stream()
                .filter(subject -> assignedSubjectIds.contains(subject.getSubjectId()))
                .map(Subject::getName)
                .toList();

        if (!duplicateSubjects.isEmpty()) {
            throw new TeacherAssignmentAlreadyExistsException(
                    "Teacher is already assigned to: "
                            + String.join(", ", duplicateSubjects)
            );
        }


        List<TeacherAssignment> assignments = subjects.stream()
                .map(subject -> mapper.toEntity(teacher, subject))
                .toList();

        teacherAssignmentRepository.saveAll(assignments);

        return assignments.stream()
                .map(mapper::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<TeacherAssignmentResponse> getAssignments(
            Long teacherId
    ) {

        return teacherAssignmentRepository
                .findByTeacherTeacherId(teacherId)
                .stream()
                .map(mapper::toResponse)
                .toList();
    }

    public List<TeacherAssignmentResponse> replaceAssignments(
            Long teacherId,
            AssignTeacherSubjectsRequest request
    ) {

        teacherAssignmentRepository.deleteByTeacherTeacherId(
                teacherId
        );

        return assignSubjects(
                teacherId,
                request
        );
    }

    public void deleteAssignment(Long assignmentId) {

        TeacherAssignment assignment =
                teacherAssignmentRepository.findById(assignmentId)
                        .orElseThrow(() ->
                                new EntityNotFoundException("Assignment not found."));

        teacherAssignmentRepository.delete(
                assignment
        );
    }

}