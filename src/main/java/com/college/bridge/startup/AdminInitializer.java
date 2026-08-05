//package com.college.bridge.startup;
//
//import com.college.bridge.auth.entity.User;
//import com.college.bridge.auth.entity.UserRole;
//import com.college.bridge.auth.repository.UserRepository;
//import lombok.RequiredArgsConstructor;
//import org.springframework.boot.CommandLineRunner;
//import org.springframework.context.annotation.Bean;
//import org.springframework.context.annotation.Configuration;
//import org.springframework.security.crypto.password.PasswordEncoder;
//
//@Configuration
//@RequiredArgsConstructor
//public class AdminInitializer {
//
//    private final UserRepository userRepository;
//    private final PasswordEncoder passwordEncoder;
//
//    @Bean
//    CommandLineRunner createAdmin() {
//        return args -> {
//
//            if (!userRepository.existsByEmail("admin@bridge.com")) {
//
//                User admin = new User();
//                admin.setEmail("admin@gmail.com");
//                admin.setName("admin");
//                admin.setPasswordHash(passwordEncoder.encode("Admin@123"));
//                admin.setRole(UserRole.ADMIN);
//
//                userRepository.save(admin);
//            }
//
//        };
//    }
//}