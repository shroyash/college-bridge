package com.college.bridge.auth.security;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import lombok.Data;

import java.time.Duration;

@Configuration
@ConfigurationProperties(prefix = "app.jwt")
@Data
public class JwtProperties {
    // For RSA keys we load PEM files. Default values point to classpath resource locations
    // You can override these in application.properties with absolute file paths.
    private String privateKeyPath = "classpath:keys/private_key.pem";
    private String publicKeyPath = "classpath:keys/public_key.pem";

    private Duration accessTokenExpiration = Duration.ofMinutes(15);
    private Duration refreshTokenExpiration = Duration.ofDays(7);
}
