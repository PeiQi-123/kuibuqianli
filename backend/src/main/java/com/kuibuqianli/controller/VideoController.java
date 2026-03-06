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
    public Result<List<String>> getVideoList() {
        List<String> videos = videoService.getAvailableVideos();
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

    @Operation(summary = "播放视频")
    @GetMapping("/play")
    public ResponseEntity<Resource> playVideo(@RequestParam String filename) {
        String path = videoService.getVideoPath(filename);
        if (path == null) {
            return ResponseEntity.notFound().build();
        }
        
        Resource resource = new FileSystemResource(path);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType("video/mp4"))
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=" + filename)
                .body(resource);
    }
}
