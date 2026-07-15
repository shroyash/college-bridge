package com.college.bridge.auth.security;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import lombok.Data;

@Configuration
@ConfigurationProperties(prefix = "app.jwt")
@Data
public class JwtProperties {
    // For RSA keys we load PEM files. Default values point to classpath resource locations
    // You can override these in application.properties with absolute file paths.
    private String privateKeyPath = "classpath:keys/private_key.pem";
    private String publicKeyPath = "classpath:keys/public_key.pem";

    // Access token expiry in milliseconds (default 15 minutes)
    private long accessTokenExpiration = 15 * 60 * 1000L;

    // Refresh token expiry in milliseconds (default 7 days)
    private long refreshTokenExpiration = 7 * 24 * 60 * 60 * 1000L;
}
