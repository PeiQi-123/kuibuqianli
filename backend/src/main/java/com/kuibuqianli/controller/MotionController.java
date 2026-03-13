package com.kuibuqianli.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.kuibuqianli.common.Result;
import com.kuibuqianli.dto.ExerciseRecordCreateDTO;
import com.kuibuqianli.service.ExerciseRecordService;
import com.kuibuqianli.service.VideoService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Paths;
import java.util.List;
import java.util.Map;

@Tag(name = "微运动管理")
@RestController
@RequestMapping("/motion")
public class MotionController {

    @Value("${ai.service.url:http://localhost:8000}")
    private String aiServiceUrl;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;
    private final VideoService videoService;
    private final ExerciseRecordService exerciseRecordService;

    public MotionController(VideoService videoService, ExerciseRecordService exerciseRecordService) {
        this.restTemplate = new RestTemplate();
        
        // 配置 UTF-8 编码
        this.restTemplate.getMessageConverters().forEach(converter -> {
            if (converter instanceof MappingJackson2HttpMessageConverter) {
                ((MappingJackson2HttpMessageConverter) converter).setDefaultCharset(StandardCharsets.UTF_8);
            }
        });
        
        this.objectMapper = new ObjectMapper();
        this.videoService = videoService;
        this.exerciseRecordService = exerciseRecordService;
    }

    @Operation(summary = "生成微运动方案")
    @PostMapping(value = "/generate", produces = "application/json;charset=UTF-8")
    @ResponseBody
    public Result<Map<String, Object>> generateMotion(@RequestBody Map<String, Object> request) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.parseMediaType("application/json;charset=UTF-8"));
            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(request, headers);

            // 先获取 String 响应
            ResponseEntity<String> rawResponse = restTemplate.exchange(
                    aiServiceUrl + "/api/motion/generate",
                    HttpMethod.POST,
                    entity,
                    String.class
            );

            String body = rawResponse.getBody();
            System.out.println("=== AI Response (raw): " + body);
            
            if (body != null) {
                // 手动解析 UTF-8 编码的 JSON
                Map<String, Object> data = objectMapper.readValue(body, Map.class);
                System.out.println("=== AI Response (parsed): " + data);

                // 尝试根据步骤自动拼接视频，并填充 video_url 字段
                try {
                    Object stepsObj = data.get("steps");
                    if (stepsObj instanceof List) {
                        @SuppressWarnings("unchecked")
                        List<String> steps = (List<String>) stepsObj;
                        String motionId = data.getOrDefault("motion_id", "motion").toString();
                        String outputPath = videoService.concatenateVideosBySteps(steps, motionId);
                        if (outputPath != null) {
                            String filename = Paths.get(outputPath).getFileName().toString();
                            String encoded = URLEncoder.encode(filename, StandardCharsets.UTF_8);
                            // 注意: 应用实际访问时会在前面加上服务器地址
                            String videoUrl = "/api/video/play?filename=" + encoded;
                            data.put("video_url", videoUrl);
                            System.out.println("=== Generated video for motion " + motionId + ": " + videoUrl);
                        }
                    }
                } catch (Exception e) {
                    // 拼接失败不影响主流程，只打印日志
                    e.printStackTrace();
                }

                return Result.success(data);
            }
            return Result.error("AI 服务响应为空");
        } catch (Exception e) {
            e.printStackTrace();
            return Result.error("调用 AI 服务失败: " + e.getMessage());
        }
    }

    @Operation(summary = "获取运动列表")
    @GetMapping("/list")
    public Result<Map<String, Object>> listMotions(@RequestParam(required = false) String activityType) {
        try {
            String url = aiServiceUrl + "/api/motion/list";
            if (activityType != null) {
                url += "?activity_type=" + activityType;
            }
            
            ResponseEntity<String> rawResponse = restTemplate.getForEntity(url, String.class);
            String body = rawResponse.getBody();
            
            if (body != null) {
                Map<String, Object> data = objectMapper.readValue(body, Map.class);
                return Result.success(data);
            }
            return Result.error("获取运动列表失败");
        } catch (Exception e) {
            return Result.error("调用 AI 服务失败: " + e.getMessage());
        }
    }

    @Operation(summary = "保存运动记录")
    @PostMapping("/record")
    public Result<String> saveExerciseRecord(@RequestParam Long userId, @RequestBody ExerciseRecordCreateDTO request) {
        boolean success = exerciseRecordService.createRecord(userId, request);
        return success ? Result.success("运动记录保存成功") : Result.error("运动记录保存失败");
    }
}
