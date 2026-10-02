package com.college.bridge;

import com.college.bridge.common.config.EnvLoader;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;

@SpringBootApplication
@EnableMethodSecurity
@EnableScheduling
public class BridgeApplication {

	static {
		EnvLoader.loadEnv();
	}

	public static void main(String[] args) {
		SpringApplication.run(BridgeApplication.class, args);
	}

}
