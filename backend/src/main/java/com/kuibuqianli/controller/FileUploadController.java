package com.kuibuqianli.controller;

import com.kuibuqianli.common.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

@Tag(name = "文件上传")
@RestController
@RequestMapping("/file")
public class FileUploadController {

    @Value("${upload.directory:C:/Users/lying/Desktop/kuibuqianli/backend/uploads}")
    private String uploadDirectory;

    @Operation(summary = "上传头像")
    @PostMapping("/avatar")
    public Result<String> uploadAvatar(@RequestParam("file") MultipartFile file) {
        if (file.isEmpty()) {
            return Result.error("请选择要上传的图片");
        }

        long maxSize = 5 * 1024 * 1024;
        if (file.getSize() > maxSize) {
            return Result.error("图片大小不能超过 5MB");
        }

        try {
            Path uploadPath = Paths.get(uploadDirectory, "avatars");
            Files.createDirectories(uploadPath);

            String originalFilename = file.getOriginalFilename();
            String extension = "";
            if (originalFilename != null && originalFilename.contains(".")) {
                extension = originalFilename.substring(originalFilename.lastIndexOf(".")).toLowerCase();
            }

            // 验证扩展名
            if (!extension.matches("\\.(jpg|jpeg|png|gif|webp)$")) {
                return Result.error("只支持 JPG、PNG、GIF、WebP 格式的图片");
            }

            String fileName = UUID.randomUUID().toString() + extension;
            Path filePath = uploadPath.resolve(fileName);
            file.transferTo(filePath.toFile());

            String avatarUrl = "/file/avatar/" + fileName;
            return Result.success(avatarUrl);

        } catch (IOException e) {
            e.printStackTrace();
            return Result.error("上传失败: " + e.getMessage());
        }
    }

    @Operation(summary = "获取头像")
    @GetMapping("/avatar/{filename}")
    public org.springframework.http.ResponseEntity<byte[]> getAvatar(@PathVariable String filename) {
        try {
            Path filePath = Paths.get(uploadDirectory, "avatars", filename);
            if (!Files.exists(filePath)) {
                return org.springframework.http.ResponseEntity.notFound().build();
            }

            byte[] imageBytes = Files.readAllBytes(filePath);
            String contentType = Files.probeContentType(filePath);
            if (contentType == null) {
                contentType = "image/jpeg";
            }

            return org.springframework.http.ResponseEntity.ok()
                    .header("Content-Type", contentType)
                    .body(imageBytes);
        } catch (IOException e) {
            return org.springframework.http.ResponseEntity.internalServerError().build();
        }
    }
}
