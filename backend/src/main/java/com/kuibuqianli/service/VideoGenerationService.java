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
 * 视频生成服务 - 连接视频生成大模型
 */
@Service
public class VideoGenerationService {

    @Value("${ai.video-api-url}")
    private String videoApiUrl;

    @Value("${ai.api-key}")
    private String apiKey;

    private final RestTemplate restTemplate = new RestTemplate();

    /**
     * 生成运动指导视频
     */
    public String generateExerciseVideo(String exerciseDescription, String style) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("exercise_description", exerciseDescription);
        requestBody.put("style", style); // "常规" 或 "有趣"
        requestBody.put("duration", "60-180"); // 1-3分钟，单位秒
        requestBody.put("video_length", 180); // 视频长度（秒）
        requestBody.put("motion_complexity", "low"); // 动作复杂度

        HttpEntity<String> requestEntity = new HttpEntity<>(JSONObject.toJSONString(requestBody), headers);

        try {
            String response = restTemplate.postForObject(videoApiUrl, requestEntity, String.class);
            // 解析响应，获取视频URL
            JSONObject jsonResponse = JSONObject.parseObject(response);
            return extractVideoUrl(jsonResponse);
        } catch (Exception e) {
            System.err.println("视频生成服务调用失败: " + e.getMessage());
            // 返回默认视频URL或空字符串
            return "";
        }
    }

    /**
     * 更新用户偏好
     */
    public void updateExercisePreference(String exerciseId, double rating) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("exercise_id", exerciseId);
        requestBody.put("rating", rating);

        HttpEntity<String> requestEntity = new HttpEntity<>(JSONObject.toJSONString(requestBody), headers);

        try {
            restTemplate.postForObject(videoApiUrl + "/update-preference", requestEntity, String.class);
        } catch (Exception e) {
            System.err.println("更新用户偏好失败: " + e.getMessage());
        }
    }

    /**
     * 解析视频URL
     */
    private String extractVideoUrl(JSONObject response) {
        try {
            // 根据具体的视频生成API响应格式解析视频URL
            if (response.containsKey("video_url")) {
                return response.getString("video_url");
            } else if (response.containsKey("result")) {
                return response.getJSONObject("result").getString("video_url");
            }
            return "";
        } catch (Exception e) {
            System.err.println("解析视频URL失败: " + e.getMessage());
            return "";
        }
    }
}
