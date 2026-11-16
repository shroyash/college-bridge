package com.college.bridge.auth.service;

import java.time.Duration;
import java.time.Instant;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import com.college.bridge.auth.security.JwtProperties;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class UserTokenRevocationService implements TokenRevocationService {

    private static final String KEY_PREFIX = "user:revoked-at:";

    private final StringRedisTemplate redisTemplate;
    private final JwtProperties jwtProperties;

    @Override
    public void revokeUserTokens(Long userId, Instant revokedAt) {
        String key = KEY_PREFIX + userId;
        Duration ttl = jwtProperties.getAccessTokenExpiration();

        redisTemplate.opsForValue()
                .set(key, String.valueOf(revokedAt.getEpochSecond()), ttl);
    }

    @Override
    public Instant getRevokedAt(Long userId) {
        String value = redisTemplate.opsForValue()
                .get(KEY_PREFIX + userId);

        if (value == null) {
            return null;
        }

        return Instant.ofEpochSecond(Long.parseLong(value));
    }

    @Override
    public boolean isTokenRevoked(Long userId, Instant issuedAt) {
        Instant revokedAt = getRevokedAt(userId);

        if (revokedAt == null) {
            return false;
        }

        return !issuedAt.isAfter(revokedAt);
    }
}