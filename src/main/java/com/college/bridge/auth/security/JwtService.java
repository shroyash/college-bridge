package com.college.bridge.auth.security;

import java.security.PrivateKey;
import java.security.PublicKey;
import java.time.Instant;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.Header;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;

@Service
public class JwtService {

    private final JwtProperties jwtProperties;
    private final PrivateKey privateKey;
    private final PublicKey publicKey;

    public JwtService(
            JwtProperties jwtProperties,
            PrivateKey privateKey,
            PublicKey publicKey
    ) {
        this.jwtProperties = jwtProperties;
        this.privateKey = privateKey;
        this.publicKey = publicKey;
    }

    public String generateAccessToken(UserDetails userDetails) {

        Map<String, Object> claims = new HashMap<>();

        if (userDetails instanceof UserPrincipal principal) {
            claims.put("userId", principal.getUserId());
            claims.put("institutionId", principal.getInstitutionId());
            claims.put("role", principal.getRole() != null ? principal.getRole().name() : null);
            claims.put("name", principal.getUser() != null ? principal.getUser().getName() : null);
        }

        List<String> roles = userDetails.getAuthorities()
                .stream()
                .map(GrantedAuthority::getAuthority)
                .toList();

        Instant now = Instant.now();
        Instant expiration = now.plusMillis(
                jwtProperties.getAccessTokenExpiration()
        );

        return Jwts.builder()
                .setHeaderParam(Header.TYPE, Header.JWT_TYPE)
                .setIssuer("bridge-api")
                .setAudience("bridge-clients")
                .setSubject(userDetails.getUsername())
                .claim("roles", roles)
                .addClaims(claims)
                .setIssuedAt(Date.from(now))
                .setExpiration(Date.from(expiration))
                .setId(UUID.randomUUID().toString())
                .signWith(privateKey, SignatureAlgorithm.RS256)
                .compact();
    }

    public String generateRefreshTokenString() {

        Instant now = Instant.now();
        Instant expiration = now.plusMillis(
                jwtProperties.getRefreshTokenExpiration()
        );

        return Jwts.builder()
                .setHeaderParam(Header.TYPE, Header.JWT_TYPE)
                .setIssuer("bridge-api")
                .setAudience("bridge-clients")
                .setSubject("refresh-token")
                .setIssuedAt(Date.from(now))
                .setExpiration(Date.from(expiration))
                .setId(UUID.randomUUID().toString())
                .signWith(privateKey, SignatureAlgorithm.RS256)
                .compact();
    }

    public Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(publicKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public Long extractInstitutionId(String token) {
        Claims claims = parseClaims(token);
        return claims.get("institutionId", Long.class);
    }

    public String extractRole(String token) {
        Claims claims = parseClaims(token);
        return claims.get("role", String.class);
    }
}