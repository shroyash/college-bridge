package com.college.bridge.auth.service;

import com.college.bridge.auth.exception.ProfileImageException;
import com.college.bridge.common.exception.BusinessRuleException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Objects;
import java.util.UUID;

@Service
@Slf4j
public class FileStorageService {

    private final Path fileStorageLocation;

    public FileStorageService() {
        this.fileStorageLocation = Paths.get("uploads").toAbsolutePath().normalize();
        try {
            Files.createDirectories(this.fileStorageLocation);
        } catch (IOException ex) {
            throw new ProfileImageException("Could not create the directory where the uploaded files will be stored.");
        }
    }

    public String storeFile(MultipartFile file) {
        if (file.isEmpty()) {
            throw new ProfileImageException("Failed to store empty file.");
        }

        String contentType = file.getContentType();
        if (contentType == null || (!contentType.equals("image/jpeg") && !contentType.equals("image/png") && !contentType.equals("image/webp"))) {
            throw new ProfileImageException("Only JPEG, PNG, and WEBP image uploads are allowed.");
        }

        if (file.getSize() > 5 * 1024 * 1024) {
            throw new ProfileImageException("File size exceeds the limit of 5MB.");
        }

        return saveFileToDisk(file);
    }

    public String storeDocument(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BusinessRuleException("Failed to store empty document file.");
        }

        if (file.getSize() > 20 * 1024 * 1024) {
            throw new BusinessRuleException("Document file size exceeds the limit of 20MB.");
        }

        return saveFileToDisk(file);
    }

    private String saveFileToDisk(MultipartFile file) {
        String originalFileName = StringUtils.cleanPath(Objects.requireNonNullElse(file.getOriginalFilename(), "file"));
        String fileExtension = "";
        int i = originalFileName.lastIndexOf('.');
        if (i > 0) {
            fileExtension = originalFileName.substring(i);
        }

        String fileName = UUID.randomUUID().toString() + fileExtension;

        try {
            if (fileName.contains("..")) {
                throw new BusinessRuleException("Filename contains invalid path sequence: " + fileName);
            }

            Path targetLocation = this.fileStorageLocation.resolve(fileName);
            Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);

            log.info("Uploaded file stored at: {}", targetLocation);
            return "/uploads/" + fileName;
        } catch (IOException ex) {
            throw new BusinessRuleException("Could not store file " + fileName + ". Please try again!");
        }
    }
}
