package com.college.bridge.auth.security;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "app.jwt")
@Data
public class JwtProperties {
    
    // Default 256-bit hex encoded HMAC-SHA secret for dev environment safety
    private String secret = "404E635266556A586E3272357538782F413F4428472B4B6250645367566B5970";
    
    private long accessTokenExpiration = 900000; // 15 mins in milliseconds
    
    private long refreshTokenExpiration = 604800000; // 7 days in milliseconds
}
