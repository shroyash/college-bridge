package com.college.bridge.notification.fcm;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
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
    private final FcmProperties fcmProperties;

    private boolean mockMode;

    public FirebaseConfig(Environment environment, FcmProperties fcmProperties) {
        this.environment = environment;
        this.fcmProperties = fcmProperties;
    }

    public String getFirebaseConfigPath() {
        return fcmProperties.getConfigPath();
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
        String path = getFirebaseConfigPath();
        Resource fileResource = new FileSystemResource(path);

        if (fileResource.exists()) {
            return fileResource;
        }

        return new ClassPathResource(path);
    }

    private void handleMissingCredentials() {
        if (isProduction()) {
            throw new IllegalStateException(
                    "Firebase credentials are required in production. " +
                            "File not found: " + getFirebaseConfigPath()
            );
        }

        mockMode = true;

        log.warn(
                "Firebase credentials not found at [{}]. " +
                        "Running FCM in MOCK mode.",
                getFirebaseConfigPath()
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
                    "Failed to initialize Firebase from: " + getFirebaseConfigPath(),
                    exception
            );
        }
    }

    private boolean isProduction() {
        return environment.matchesProfiles(String.valueOf(Profiles.of("prod")));
    }
}