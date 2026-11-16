package com.college.bridge.dashboard.service;

import com.college.bridge.academic.repository.AcademicProgramRepository;
import com.college.bridge.academic.repository.SubjectRepository;
import com.college.bridge.auth.repository.StudentRepository;
import com.college.bridge.auth.repository.TeacherRepository;
import com.college.bridge.common.tenant.TenantContext;
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
public class AdminDashboardService {

    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final AcademicProgramRepository academicProgramRepository;
    private final SubjectRepository subjectRepository;

    public DashboardResponse getDashboard() {

        Long tenantId = TenantContext.get();

        List<DashboardMetric> metrics = new ArrayList<>();

        metrics.add(DashboardMetric.builder()
                .key("students")
                .title("Total Students")
                .value(studentRepository.countByUser_Institution_InstitutionId(tenantId))
                .build());

        metrics.add(DashboardMetric.builder()
                .key("teachers")
                .title("Total Teachers")
                .value(teacherRepository.countByUser_Institution_InstitutionId(tenantId))
                .build());

        metrics.add(DashboardMetric.builder()
                .key("programs")
                .title("Total Programs")
                .value(academicProgramRepository.countByInstitution_InstitutionIdAndDeletedFalse(tenantId))
                .build());

        metrics.add(DashboardMetric.builder()
                .key("subjects")
                .title("Total Subjects")
                .value(subjectRepository.countActiveByInstitutionId(tenantId))
                .build());

        return DashboardResponse.builder()
                .metrics(metrics)
                .build();
    }
}