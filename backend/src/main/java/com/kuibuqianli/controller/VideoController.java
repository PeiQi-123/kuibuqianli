package com.kuibuqianli.controller;

import com.kuibuqianli.common.Result;
import com.kuibuqianli.service.VideoService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import java.util.List;
import java.util.Map;

@Tag(name = "视频管理")
@RestController
@RequestMapping("/video")
public class VideoController {

    @Autowired
    private VideoService videoService;

    @Operation(summary = "获取可用视频列表")
    @GetMapping("/list")
    public Result<List<String>> getVideoList(
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) String bodyPart
    ) {
        List<String> videos = videoService.getAvailableVideos(userId, bodyPart);
        return Result.success(videos);
    }

    @Operation(summary = "根据关键词查找视频")
    @GetMapping("/search")
    public Result<String> searchVideo(@RequestParam String keyword) {
        String path = videoService.findVideoByKeyword(keyword);
        if (path != null) {
            return Result.success(path);
        }
        return Result.error("未找到匹配的视频");
    }

    @Operation(summary = "模糊搜索视频（匹配度>30%）")
    @GetMapping("/fuzzy-search")
    public Result<String> fuzzySearchVideo(@RequestParam String text) {
        String path = videoService.fuzzyFindVideoByMatchRate(text);
        if (path != null) {
            return Result.success(path);
        }
        return Result.error("未找到匹配度超过30%的视频");
    }

    @Operation(summary = "生成或查找视频（核心API）")
    @PostMapping("/find-or-generate")
    public Result<Map<String, Object>> findOrGenerateVideo(@RequestBody Map<String, Object> request) {
        @SuppressWarnings("unchecked")
        List<String> steps = (List<String>) request.get("steps");
        String motionId = (String) request.getOrDefault("motionId", "motion");
        
        if (steps == null || steps.isEmpty()) {
            return Result.error("steps不能为空");
        }
        
        String videoPath = videoService.findOrGenerateVideo(steps, motionId);
        
        if (videoPath != null) {
            String fileName = videoPath.contains("/") 
                ? videoPath.substring(videoPath.lastIndexOf("/") + 1)
                : videoPath.substring(videoPath.lastIndexOf("\\") + 1);
            return Result.success(Map.of(
                "videoPath", videoPath,
                "fileName", fileName,
                "generated", !videoPath.contains("output")
            ));
        }
        
        return Result.error("无法生成或找到视频");
    }

    @Operation(summary = "为每个步骤生成或查找视频")
    @PostMapping("/find-or-generate-steps")
    public Result<List<Map<String, Object>>> findOrGenerateVideosForSteps(@RequestBody Map<String, Object> request) {
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> steps = (List<Map<String, Object>>) request.get("steps");
        String motionId = (String) request.getOrDefault("motionId", "motion");
        
        if (steps == null || steps.isEmpty()) {
            return Result.error("steps不能为空");
        }
        
        System.out.println("DEBUG: 为 " + steps.size() + " 个步骤生成视频");
        
        List<Map<String, Object>> result = videoService.findOrGenerateVideosForSteps(steps, motionId);
        
        return Result.success(result);
    }
    
    @Operation(summary = "Find local videos for steps (no generation)")
    @PostMapping("/find-steps")
    public Result<List<Map<String, Object>>> findVideosForSteps(@RequestBody Map<String, Object> request) {
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> steps = (List<Map<String, Object>>) request.get("steps");
        String motionId = (String) request.getOrDefault("motionId", "motion");
        
        if (steps == null || steps.isEmpty()) {
            return Result.error("steps cannot be empty");
        }
        
        System.out.println("DEBUG: Find local videos for " + steps.size() + " steps");
        
        List<Map<String, Object>> result = videoService.findVideosForSteps(steps, motionId);
        
        return Result.success(result);
    }
    
    @Operation(summary = "Generate videos for steps")
    @PostMapping("/generate-steps")
    public Result<List<Map<String, Object>>> generateVideosForSteps(@RequestBody Map<String, Object> request) {
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> steps = (List<Map<String, Object>>) request.get("steps");
        String motionId = (String) request.getOrDefault("motionId", "motion");
        
        if (steps == null || steps.isEmpty()) {
            return Result.error("steps cannot be empty");
        }
        
        System.out.println("DEBUG: Generate videos for " + steps.size() + " steps");
        
        List<Map<String, Object>> result = videoService.generateVideosForSteps(steps, motionId);
        
        return Result.success(result);
    }

    @Operation(summary = "调用AI生成视频")
    @PostMapping("/generate")
    public Result<String> generateVideo(@RequestBody Map<String, Object> request) {
        @SuppressWarnings("unchecked")
        List<String> steps = (List<String>) request.get("steps");
        String motionId = (String) request.getOrDefault("motionId", "motion");
        
        if (steps == null || steps.isEmpty()) {
            return Result.error("steps不能为空");
        }
        
        String videoPath = videoService.generateVideoFromSteps(steps, motionId);
        if (videoPath != null) {
            return Result.success(videoPath);
        }
        return Result.error("视频生成失败");
    }

    @Operation(summary = "拼接视频")
    @PostMapping("/concatenate")
    public Result<String> concatenateVideos(@RequestBody Map<String, Object> request) {
        @SuppressWarnings("unchecked")
        List<String> keywords = (List<String>) request.get("keywords");
        String outputName = (String) request.getOrDefault("outputName", "output");
        
        String outputPath = videoService.concatenateVideos(keywords, outputName);
        if (outputPath != null) {
            return Result.success(outputPath);
        }
        return Result.error("视频拼接失败");
    }

    @Operation(summary = "按步骤拼接视频")
    @PostMapping("/concatenate-by-steps")
    public Result<String> concatenateBySteps(@RequestBody Map<String, Object> request) {
        @SuppressWarnings("unchecked")
        List<String> steps = (List<String>) request.get("steps");
        String motionId = (String) request.getOrDefault("motionId", "motion");

        if (steps == null || steps.isEmpty()) {
            return Result.error("steps 不能为空");
        }

        String outputPath = videoService.concatenateVideosBySteps(steps, motionId);
        if (outputPath != null) {
            return Result.success(outputPath);
        }
        return Result.error("按步骤拼接视频失败");
    }

    @Operation(summary = "播放视频(POST)")
    @PostMapping("/play")
    public ResponseEntity<?> playVideo(@RequestBody Map<String, String> request) {
        String filename = request.get("filename");
        System.out.println("DEBUG playVideo POST: filename=" + filename);
        
        if (filename == null || filename.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("code", 400, "message", "filename不能为空"));
        }
        
        String path = videoService.getVideoPath(filename);
        System.out.println("DEBUG playVideo POST: path=" + path);
        
        if (path == null) {
            return ResponseEntity.ok(Map.of("code", 404, "message", "视频文件不存在"));
        }
        
        try {
            String encodedName = java.net.URLEncoder.encode(filename, "UTF-8");
            String streamUrl = "/video/stream?file=" + encodedName;
            System.out.println("DEBUG playVideo POST: streamUrl=" + streamUrl);
            return ResponseEntity.ok(Map.of("code", 200, "data", Map.of("url", streamUrl)));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("code", 500, "message", "生成播放URL失败"));
        }
    }

    @Operation(summary = "流式播放视频")
    @GetMapping("/stream")
    public ResponseEntity<org.springframework.core.io.InputStreamResource> streamVideo(@RequestParam String file) {
        System.out.println("DEBUG streamVideo: file=" + file);
        String filename;
        try {
            filename = java.net.URLDecoder.decode(file, "UTF-8");
        } catch (Exception e) {
            filename = file;
        }
        
        String path = videoService.getVideoPath(filename);
        System.out.println("DEBUG streamVideo: path=" + path);
        
        if (path == null) {
            return ResponseEntity.notFound().build();
        }
        
        try {
            java.nio.file.Path filePath = java.nio.file.Paths.get(path);
            if (!java.nio.file.Files.exists(filePath)) {
                return ResponseEntity.notFound().build();
            }
            
            org.springframework.core.io.InputStreamResource resource = 
                new org.springframework.core.io.InputStreamResource(
                    java.nio.file.Files.newInputStream(filePath)
                );
            
            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType("video/mp4"))
                    .contentLength(java.nio.file.Files.size(filePath))
                    .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + filename + "\"")
                    .body(resource);
        } catch (Exception e) {
            System.err.println("Error streaming video: " + e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }
}
