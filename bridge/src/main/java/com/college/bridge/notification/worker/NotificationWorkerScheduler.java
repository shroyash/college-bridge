package com.college.bridge.notification.worker;

import com.college.bridge.notification.dto.NotificationJobExecutionDto;
import com.college.bridge.notification.service.NotificationJobClaimService;
import com.college.bridge.notification.service.NotificationJobProcessor;
import jakarta.annotation.PreDestroy;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import java.util.List;
import java.util.concurrent.*;

@Component
@Slf4j
public class NotificationWorkerScheduler {

    private final NotificationJobClaimService jobClaimService;
    private final NotificationJobProcessor jobProcessor;
    private final ThreadPoolExecutor workerPool;
    private static final int POOL_SIZE = 4;

    public NotificationWorkerScheduler(
            NotificationJobClaimService jobClaimService,
            NotificationJobProcessor jobProcessor) {
        this.jobClaimService = jobClaimService;
        this.jobProcessor = jobProcessor;
        this.workerPool = new ThreadPoolExecutor(
                POOL_SIZE, POOL_SIZE, 0L, TimeUnit.MILLISECONDS,
                new LinkedBlockingQueue<>(POOL_SIZE),
                new ThreadPoolExecutor.AbortPolicy()
        );
    }

    @Scheduled(fixedDelayString = "${notification.worker.poll-interval-ms:3000}")
    public void pollAndProcessJobs() {
        try {
            int activeThreads = workerPool.getActiveCount();
            int queuedTasks = workerPool.getQueue().size();

            int freeSlots = POOL_SIZE - activeThreads - queuedTasks;

            if (freeSlots <= 0) {
                return;
            }

            List<NotificationJobExecutionDto> claimedJobs = jobClaimService.claimJobsAtomic(freeSlots);
            if (claimedJobs.isEmpty()) {
                return;
            }

            for (NotificationJobExecutionDto jobDto : claimedJobs) {
                workerPool.submit(() -> {
                    try {
                        jobProcessor.processJob(jobDto);
                    } catch (Exception e) {
                        log.error("Unhandled error processing notification job {}: {}", jobDto.getJobId(), e.getMessage());
                    }
                });
            }
        } catch (Exception e) {
            log.error("Error during notification worker polling: {}", e.getMessage());
        }
    }

    @PreDestroy
    public void shutdown() {
        log.debug("Gracefully shutting down NotificationWorkerScheduler thread pool...");
        workerPool.shutdown();
        try {
            if (!workerPool.awaitTermination(15, TimeUnit.SECONDS)) {
                workerPool.shutdownNow();
            }
        } catch (InterruptedException e) {
            workerPool.shutdownNow();
            Thread.currentThread().interrupt();
        }
    }
}
