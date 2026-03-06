package com.kuibuqianli.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.kuibuqianli.common.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter;
import java.nio.charset.StandardCharsets;
import java.util.Map;

@Tag(name = "微运动管理")
@RestController
@RequestMapping("/motion")
public class MotionController {

    @Value("${ai.service.url:http://localhost:8000}")
    private String aiServiceUrl;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public MotionController() {
        this.restTemplate = new RestTemplate();
        
        // 配置 UTF-8 编码
        this.restTemplate.getMessageConverters().forEach(converter -> {
            if (converter instanceof MappingJackson2HttpMessageConverter) {
                ((MappingJackson2HttpMessageConverter) converter).setDefaultCharset(StandardCharsets.UTF_8);
            }
        });
        
        this.objectMapper = new ObjectMapper();
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
}
