package com.college.bridge;

import com.college.bridge.common.config.EnvLoader;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class BridgeApplicationTests {

	static {
		EnvLoader.loadEnv();
	}

	@Test
	void contextLoads() {
	}

}
