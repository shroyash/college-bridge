package com.college.bridge.notification.fcm;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * External configuration properties for Firebase Cloud Messaging.
 */
@Configuration
@ConfigurationProperties(prefix = "firebase")
@Getter
@Setter
public class FcmProperties {

    /**
     * Path to the Firebase service account JSON file.
     */
    private String configPath = "keys/firebase-service-account.json";
}
