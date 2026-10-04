package com.college.bridge.common.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.Executor;

@Configuration
@EnableAsync
@Slf4j
public class AsyncConfig {

    @Bean(name = "notificationTaskExecutor")
    public Executor notificationTaskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(4);
        executor.setMaxPoolSize(10);
        executor.setQueueCapacity(500);
        executor.setThreadNamePrefix("notif-event-");
        executor.setRejectedExecutionHandler((runnable, exec) ->
                log.warn("notificationTaskExecutor queue full! Dropping event task: {}", runnable)
        );
        executor.initialize();
        return executor;
    }

    @Bean(name = "topicRefreshTaskExecutor")
    public Executor topicRefreshTaskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(2);
        executor.setMaxPoolSize(6);
        executor.setQueueCapacity(300);
        executor.setThreadNamePrefix("fcm-topic-refresh-");
        executor.setRejectedExecutionHandler((runnable, exec) ->
                log.warn("topicRefreshTaskExecutor queue full! Dropping topic refresh task: {}", runnable)
        );
        executor.initialize();
        return executor;
    }
}

