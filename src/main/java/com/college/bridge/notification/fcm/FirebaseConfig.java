package com.college.bridge.notification.fcm;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.core.env.Profiles;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import java.io.IOException;
import java.io.InputStream;

@Configuration
@Slf4j
@Getter
public class FirebaseConfig {

    private final Environment environment;

    @Value("${firebase.config.path:keys/firebase-service-account.json}")
    private String firebaseConfigPath;

    private boolean mockMode;

    public FirebaseConfig(Environment environment) {
        this.environment = environment;
    }

    @PostConstruct
    public void initializeFirebase() {
        if (!FirebaseApp.getApps().isEmpty()) {
            return;
        }

        Resource resource = resolveFirebaseCredentials();

        if (!resource.exists()) {
            handleMissingCredentials();
            return;
        }

        initializeFromCredentials(resource);
    }

    private Resource resolveFirebaseCredentials() {
        Resource fileResource = new FileSystemResource(firebaseConfigPath);

        if (fileResource.exists()) {
            return fileResource;
        }

        return new ClassPathResource(firebaseConfigPath);
    }

    private void handleMissingCredentials() {
        if (isProduction()) {
            throw new IllegalStateException(
                    "Firebase credentials are required in production. " +
                            "File not found: " + firebaseConfigPath
            );
        }

        mockMode = true;

        log.warn(
                "Firebase credentials not found at [{}]. " +
                        "Running FCM in MOCK mode.",
                firebaseConfigPath
        );
    }

    private void initializeFromCredentials(Resource resource) {
        try (InputStream inputStream = resource.getInputStream()) {

            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(inputStream))
                    .build();

            FirebaseApp.initializeApp(options);

            log.debug("Firebase Admin SDK initialized successfully.");

        } catch (IOException | RuntimeException exception) {
            throw new IllegalStateException(
                    "Failed to initialize Firebase from: " + firebaseConfigPath,
                    exception
            );
        }
    }

    private boolean isProduction() {
        return environment.matchesProfiles(String.valueOf(Profiles.of("prod")));
    }
}