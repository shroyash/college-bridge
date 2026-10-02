package com.college.bridge.notification.service;

import com.college.bridge.notification.dto.NotificationJobExecutionDto;
import com.college.bridge.notification.entity.JobStatus;
import com.college.bridge.notification.repository.NotificationJobRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class NotificationJobClaimService {

    private final NotificationJobRepository jobRepository;

    @Value("${notification.worker.lease-duration-seconds:120}")
    private int leaseDurationSeconds;

    @Transactional
    public List<NotificationJobExecutionDto> claimJobsAtomic(int batchSize) {
        Instant now = Instant.now();
        List<Long> jobIds = jobRepository.findClaimableJobIds(now, batchSize);
        if (jobIds.isEmpty()) {
            return List.of();
        }

        Instant leaseExpiresAt = now.plus(leaseDurationSeconds, ChronoUnit.SECONDS);
        jobRepository.markJobsProcessing(jobIds, JobStatus.PROCESSING, now, leaseExpiresAt);

        List<NotificationJobExecutionDto> dtoList = new ArrayList<>();
        for (Long jobId : jobIds) {
            jobRepository.findByIdWithNotification(jobId).ifPresent(job -> {
                dtoList.add(NotificationJobExecutionDto.builder()
                        .jobId(job.getJobId())
                        .notificationId(job.getNotification().getNotificationId())
                        .institutionId(job.getInstitutionId())
                        .title(job.getNotification().getTitle())
                        .body(job.getNotification().getMessage())
                        .targetType(job.getNotification().getTargetType())
                        .targetId(job.getNotification().getTargetId())
                        .attemptCount(job.getAttemptCount())
                        .maxAttempts(job.getMaxAttempts())
                        .build());
            });
        }
        return dtoList;
    }
}
