package com.college.bridge;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class BridgeApplicationTests {

	static {
		BridgeApplication.loadEnv();
	}

	@Test
	void contextLoads() {
	}

}
