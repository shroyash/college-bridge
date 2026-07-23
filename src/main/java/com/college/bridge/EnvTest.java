package com.college.bridge;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class EnvTest implements CommandLineRunner {

    @Value("${APP_NAME:NOT_FOUND}")
    private String appName;

    @Value("${DB_HOST:NOT_FOUND}")
    private String dbHost;

    @Override
    public void run(String... args) {
        System.out.println("APP_NAME = " + appName);
        System.out.println("DB_HOST = " + dbHost);
    }
}