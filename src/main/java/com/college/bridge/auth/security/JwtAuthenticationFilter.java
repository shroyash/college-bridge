package com.college.bridge.auth.security;

import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.entity.UserStatus;
import com.college.bridge.auth.service.UserTokenRevocationService;
import com.college.bridge.common.tenant.TenantContext;
import com.college.bridge.institution.entity.InstitutionStatus;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.NonNull;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Instant;
import java.util.Date;

@Component
@Slf4j
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final CustomUserDetailsService userDetailsService;
    private final UserTokenRevocationService userTokenRevocationService;

    public JwtAuthenticationFilter(
            JwtService jwtService,
            CustomUserDetailsService userDetailsService,
            UserTokenRevocationService userTokenRevocationService
    ) {
        this.jwtService = jwtService;
        this.userDetailsService = userDetailsService;
        this.userTokenRevocationService = userTokenRevocationService;
    }

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain
    ) throws ServletException, IOException {

        String authHeader = request.getHeader("Authorization");

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            try {
                filterChain.doFilter(request, response);
            } finally {
                TenantContext.clear();
            }
            return;
        }

        String jwt = authHeader.substring(7);

        try {
            Claims claims = jwtService.parseClaims(jwt);
            String userEmail = claims.getSubject();
            Long userId = claims.get("userId", Long.class);
            Long institutionId = claims.get("institutionId", Long.class);
            Instant issuedAt = claims.getIssuedAt().toInstant();
            Date expiration = claims.getExpiration();

            if (userEmail == null
                    || userId == null
                    || issuedAt == null
                    || expiration == null) {
                filterChain.doFilter(request, response);
                return;
            }

            if (expiration.before(new Date())) {
                log.debug("JWT token has expired");
                filterChain.doFilter(request, response);
                return;
            }

            // Populate request-scoped TenantContext after token validation
            if (institutionId != null) {
                TenantContext.set(institutionId);
            }

            if (SecurityContextHolder.getContext().getAuthentication() == null) {
                UserDetails userDetails;
                if (institutionId != null) {
                    userDetails = userDetailsService.loadUserByInstitutionIdAndEmail(institutionId, userEmail);
                } else {
                    userDetails = userDetailsService.loadUserByUsername(userEmail);
                }

                if (userDetails instanceof UserPrincipal principal) {
                    User user = principal.getUser();
                    if (user.getRole() != UserRole.SUPER_ADMIN) {
                        if (user.getInstitution() == null
                                || user.getInstitution().getStatus() != InstitutionStatus.ACTIVE
                                || user.getStatus() != UserStatus.ACTIVE) {
                            log.warn("Rejected JWT request for user ID: {} - Institution status: {}, User status: {}",
                                    user.getUserId(),
                                    user.getInstitution() != null ? user.getInstitution().getStatus() : "null",
                                    user.getStatus());
                            TenantContext.clear();
                            filterChain.doFilter(request, response);
                            return;
                        }
                    }
                }

                boolean tokenRevoked = userTokenRevocationService.isTokenRevoked(
                        userId,
                        issuedAt
                );

                if (tokenRevoked) {
                    log.warn("Rejected revoked token for user ID: {}", userId);
                    filterChain.doFilter(request, response);
                    return;
                }

                if (!userEmail.equals(userDetails.getUsername())) {
                    log.warn("JWT username does not match user details");
                    filterChain.doFilter(request, response);
                    return;
                }

                UsernamePasswordAuthenticationToken authToken =
                        new UsernamePasswordAuthenticationToken(
                                userDetails,
                                null,
                                userDetails.getAuthorities()
                        );

                authToken.setDetails(
                        new WebAuthenticationDetailsSource()
                                .buildDetails(request)
                );

                SecurityContextHolder
                        .getContext()
                        .setAuthentication(authToken);
            }

            filterChain.doFilter(request, response);

        } catch (ExpiredJwtException e) {
            log.debug("JWT token has expired");
            filterChain.doFilter(request, response);
        } catch (JwtException | IllegalArgumentException e) {
            log.debug("Invalid JWT token: {}", e.getMessage());
            filterChain.doFilter(request, response);
        } catch (Exception e) {
            log.error("Could not establish security context: {}", e.getMessage());
            filterChain.doFilter(request, response);
        } finally {
            // Always clear ThreadLocal TenantContext in a finally block
            TenantContext.clear();
        }
    }
}