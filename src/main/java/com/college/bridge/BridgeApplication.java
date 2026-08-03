package com.college.bridge;

import com.college.bridge.common.config.EnvLoader;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.List;

@SpringBootApplication
public class BridgeApplication {

	static {
		EnvLoader.loadEnv();
	}

	public static void main(String[] args) {
		SpringApplication.run(BridgeApplication.class, args);
	}

}

