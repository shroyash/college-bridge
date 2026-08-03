package com.college.bridge.dashboard.service;

import com.college.bridge.auth.repository.StudentRepository;
import com.college.bridge.auth.repository.TeacherRepository;
import com.college.bridge.clazz.repository.ClassRepository;
import com.college.bridge.dashboard.dto.DashboardMetric;
import com.college.bridge.dashboard.dto.DashboardResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class DashboardServiceImpl implements DashboardService {

    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final ClassRepository classRepository;

    @Override
    public DashboardResponse getDashboard() {

        List<DashboardMetric> metrics = new ArrayList<>();

        metrics.add(
                DashboardMetric.builder()
                        .key("students")
                        .title("Total Students")
                        .value(studentRepository.count())
                        .build());

        metrics.add(
                DashboardMetric.builder()
                        .key("teachers")
                        .title("Total Teachers")
                        .value(teacherRepository.count())
                        .build());

        metrics.add(
                DashboardMetric.builder()
                        .key("classes")
                        .title("Total Classes")
                        .value(classRepository.count())
                        .build());

        return DashboardResponse.builder()
                .metrics(metrics)
                .build();
    }
}