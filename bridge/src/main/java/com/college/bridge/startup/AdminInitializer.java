package com.college.bridge.startup;

import com.college.bridge.auth.entity.User;
import com.college.bridge.auth.entity.UserRole;
import com.college.bridge.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
@RequiredArgsConstructor
@Slf4j
public class AdminInitializer {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${SUPER_ADMIN_EMAIL:}")
    private String superAdminEmail;

    @Value("${SUPER_ADMIN_PASSWORD:}")
    private String superAdminPassword;

    @Bean
    CommandLineRunner createAdmin() {
        return args -> {

            if (superAdminEmail == null || superAdminEmail.isBlank()
                    || superAdminPassword == null || superAdminPassword.isBlank()) {
                log.info("SUPER_ADMIN_EMAIL or SUPER_ADMIN_PASSWORD not configured. Skipping admin seeding.");
                return;
            }

            if (!userRepository.existsByEmail(superAdminEmail)) {

                User admin = new User();
                admin.setEmail(superAdminEmail);
                admin.setName("Super Admin");
                admin.setPasswordHash(passwordEncoder.encode(superAdminPassword));
                admin.setRole(UserRole.SUPER_ADMIN);

                userRepository.save(admin);
                log.info("Super Admin account created for: {}", superAdminEmail);
            }

        };
    }
}