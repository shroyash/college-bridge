package com.college.bridge.auth.service;


import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Instant;

@Service
@RequiredArgsConstructor
public class UserTokenRevocationService {

    private static final String KEY_PREFIX = "user:revoked-at:";

    private final StringRedisTemplate redisTemplate;

    public void revokeUserTokens(Long userId, Instant revokedAt) {
        String key = KEY_PREFIX + userId;

        redisTemplate.opsForValue()
                .set(key, String.valueOf(revokedAt.getEpochSecond()));
    }

    public Instant getRevokedAt(Long userId) {
        String value = redisTemplate.opsForValue()
                .get(KEY_PREFIX + userId);

        if (value == null) {
            return null;
        }

        return Instant.ofEpochSecond(Long.parseLong(value));
    }

    public boolean isTokenRevoked(Long userId, Instant issuedAt) {
        Instant revokedAt = getRevokedAt(userId);

        if (revokedAt == null) {
            return false;
        }

        return !issuedAt.isAfter(revokedAt);
    }
}