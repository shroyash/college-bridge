package com.college.bridge.auth.security;

import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.util.FileCopyUtils;

@Configuration
public class RSAKeyConfig {

    @Value("${app.jwt.privateKeyPath}")
    private Resource privateKeyResource;

    @Value("${app.jwt.publicKeyPath}")
    private Resource publicKeyResource;

    @Bean
    public PrivateKey privateKey() throws Exception {
        String pem = readPem(privateKeyResource);
        String clean = pem
                .replaceAll("-----BEGIN (.*)PRIVATE KEY-----", "")
                .replaceAll("-----END (.*)PRIVATE KEY-----", "")
                .replaceAll("\\s", "");
        byte[] decoded = Base64.getDecoder().decode(clean);
        PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(decoded);
        KeyFactory kf = KeyFactory.getInstance("RSA");
        return kf.generatePrivate(keySpec);
    }

    @Bean
    public PublicKey publicKey() throws Exception {
        String pem = readPem(publicKeyResource);
        String clean = pem
                .replaceAll("-----BEGIN (.*)PUBLIC KEY-----", "")
                .replaceAll("-----END (.*)PUBLIC KEY-----", "")
                .replaceAll("\\s", "");
        byte[] decoded = Base64.getDecoder().decode(clean);
        X509EncodedKeySpec keySpec = new X509EncodedKeySpec(decoded);
        KeyFactory kf = KeyFactory.getInstance("RSA");
        return kf.generatePublic(keySpec);
    }

    private String readPem(Resource resource) throws Exception {
        try (InputStreamReader reader = new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8)) {
            return FileCopyUtils.copyToString(reader);
        }
    }
}
