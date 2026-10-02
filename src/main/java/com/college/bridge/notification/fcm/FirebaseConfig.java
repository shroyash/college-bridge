package com.college.bridge.notification.fcm;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;

import java.io.InputStream;
import java.util.Arrays;

@Configuration
@Slf4j
public class FirebaseConfig {

    @Value("${firebase.config.path:keys/firebase-service-account.json}")
    private String firebaseConfigPath;

    @Value("${spring.profiles.active:dev}")
    private String activeProfiles;

    @Getter
    private boolean mockMode = false;

    @PostConstruct
    public void initializeFirebase() {
        if (!FirebaseApp.getApps().isEmpty()) {
            return;
        }

        boolean isProd = Arrays.asList(activeProfiles.split(",")).contains("prod");

        try {
            Resource resource = new FileSystemResource(firebaseConfigPath);
            if (!resource.exists()) {
                // Also check classpath if not found on filesystem
                resource = new org.springframework.core.io.ClassPathResource(firebaseConfigPath);
            }

            if (!resource.exists()) {
                if (isProd) {
                    throw new IllegalStateException("Production environment requires valid Firebase credentials at: " + firebaseConfigPath);
                } else {
                    mockMode = true;
                    log.warn("Firebase credentials not found at [{}]. Running FCM in safe MOCK mode for environment: {}", firebaseConfigPath, activeProfiles);
                    return;
                }
            }

            try (InputStream serviceAccount = resource.getInputStream()) {
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .build();

                FirebaseApp.initializeApp(options);
                log.debug("FirebaseApp initialized successfully with credentials from {}", firebaseConfigPath);
            }
        } catch (Exception e) {
            if (isProd) {
                throw new IllegalStateException("Failed to initialize Firebase in production: " + e.getMessage(), e);
            } else {
                mockMode = true;
                log.warn("Error loading Firebase credentials ({}). Falling back to MOCK mode.", e.getMessage());
            }
        }
    }
}
