package com.college.bridge.auth.service;

import java.time.Instant;

public interface TokenRevocationService {

    void revokeUserTokens(Long userId, Instant revokedAt);

    Instant getRevokedAt(Long userId);

    boolean isTokenRevoked(Long userId, Instant issuedAt);
}
