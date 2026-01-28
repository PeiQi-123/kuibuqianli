package com.kuibuqianli.service;

import com.alibaba.fastjson.JSONObject;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

/**
 * 语义分析服务 - 连接语义大模型
 */
@Service
public class SemanticAnalysisService {

    @Value("${ai.semantic-api-url}")
    private String semanticApiUrl;

    @Value("${ai.api-key}")
    private String apiKey;

    private final RestTemplate restTemplate = new RestTemplate();

    /**
     * 分析用户活动类型
     */
    public String analyzeActivityType(String userActivityDescription) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("prompt", "分析用户的活动类型：" + userActivityDescription);
        requestBody.put("temperature", 0.7);
        requestBody.put("max_tokens", 100);

        HttpEntity<String> requestEntity = new HttpEntity<>(JSONObject.toJSONString(requestBody), headers);

        try {
            String response = restTemplate.postForObject(semanticApiUrl, requestEntity, String.class);
            // 解析响应，提取活动类型
            JSONObject jsonResponse = JSONObject.parseObject(response);
            return extractContent(jsonResponse);
        } catch (Exception e) {
            // 记录日志并返回默认值
            System.err.println("语义分析服务调用失败: " + e.getMessage());
            return "久坐";
        }
    }

    /**
     * 生成运动建议
     */
    public String generateExerciseRecommendation(String activityType, String stylePreference) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);

        String prompt = String.format(
            "为%s活动类型的用户提供%s风格的微运动建议，时长约1-3分钟，包括具体的动作描述",
            activityType, stylePreference
        );

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("prompt", prompt);
        requestBody.put("temperature", 0.7);
        requestBody.put("max_tokens", 200);

        HttpEntity<String> requestEntity = new HttpEntity<>(JSONObject.toJSONString(requestBody), headers);

        try {
            String response = restTemplate.postForObject(semanticApiUrl, requestEntity, String.class);
            JSONObject jsonResponse = JSONObject.parseObject(response);
            return extractContent(jsonResponse);
        } catch (Exception e) {
            System.err.println("运动建议生成失败: " + e.getMessage());
            return "建议进行简单的颈部转动和肩膀放松运动";
        }
    }

    /**
     * 解析AI响应内容
     */
    private String extractContent(JSONObject response) {
        // 根据具体的AI API响应格式解析内容
        // 这里假设响应结构为 { "choices": [{ "message": { "content": "..." } }] }
        try {
            if (response.containsKey("choices")) {
                return response.getJSONArray("choices")
                        .getJSONObject(0)
                        .getJSONObject("message")
                        .getString("content");
            }
            return response.getString("content");
        } catch (Exception e) {
            System.err.println("解析AI响应失败: " + e.getMessage());
            return "无法生成有效的运动建议";
        }
    }
}
