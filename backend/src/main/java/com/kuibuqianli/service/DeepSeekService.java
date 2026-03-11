package com.kuibuqianli.service;

import com.kuibuqianli.dto.DeepSeekRequest;
import com.kuibuqianli.dto.DeepSeekResponse;
import com.kuibuqianli.dto.PromptRequest;
import com.kuibuqianli.dto.PromptResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.ResourceAccessException;

import java.util.*;

@Slf4j
@Service
public class DeepSeekService {

    @Value("${deepseek.api.key}")
    private String apiKey;

    @Value("${deepseek.api.url}")
    private String apiUrl;

    @Value("${deepseek.api.model}")
    private String model;

    @Value("${deepseek.api.connect-timeout:30000}")
    private int connectTimeout;

    @Value("${deepseek.api.read-timeout:60000}")
    private int readTimeout;

    @Value("${deepseek.api.max-tokens:1000}")
    private int maxTokens;

    @Value("${deepseek.api.temperature:0.7}")
    private double temperature;

    @Value("${micro-motion.default-duration:60}")
    private int defaultDuration;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public DeepSeekService() {
        this.restTemplate = new RestTemplate();
        this.objectMapper = new ObjectMapper();
    }

    /**
     * 生成微运动提示词
     * @param request 提示词请求
     * @return 提示词响应
     */
    public PromptResponse generateMicroMotionPrompt(PromptRequest request) {
        log.info("开始生成微运动提示词 - bodyPart: {}, postureInfo: {}",
                request.getBodyPart(), request.getPostureInfo());

        try {
            // 1. 构建系统提示词
            String systemPrompt = buildSystemPrompt();

            // 2. 构建用户提示词
            String userPrompt = buildUserPrompt(request);

            log.debug("系统提示词: {}", systemPrompt);
            log.debug("用户提示词: {}", userPrompt);

            // 3. 调用DeepSeek API
            DeepSeekResponse apiResponse = callDeepSeekAPI(systemPrompt, userPrompt);

            // 4. 解析响应并生成返回结果
            PromptResponse response = parseResponse(apiResponse, request);

            log.info("微运动提示词生成成功 - token使用: {}", response.getApiUsage());
            return response;

        } catch (HttpClientErrorException e) {
            log.error("DeepSeek API HTTP错误: {}", e.getResponseBodyAsString(), e);
            return PromptResponse.error("API调用失败: " + e.getStatusCode());
        } catch (ResourceAccessException e) {
            log.error("DeepSeek API连接超时", e);
            return PromptResponse.error("API连接超时，请稍后重试");
        } catch (Exception e) {
            log.error("调用DeepSeek API失败", e);
            return PromptResponse.error("生成微运动提示词失败: " + e.getMessage());
        }
    }

    /**
     * 构建系统提示词
     */
    private String buildSystemPrompt() {
        return """
            你是一个专业的微运动健康顾问。请根据用户的身体部位、当前姿态和个人信息，
            生成简短、实用、安全的微运动建议。
            
            【要求】
            1. 运动建议要简单易行，可以在办公位或家里完成，不需要特殊设备
            2. 考虑用户的BMI和年龄，避免不适合的运动
            3. 每次建议包含2-3个微运动动作
            4. 每个动作要说明：动作名称、具体做法、持续时间、注意事项
            5. 用友好、鼓励的语气，像私人教练一样
            6. 返回格式要清晰易读，使用emoji增加可读性
            7. 如果用户有某些健康禁忌（如腰伤、高血压等），要特别提醒
            8. 结合用户的当前姿态给出针对性建议
            
            【输出格式】
            🎯 针对【部位】的微运动建议
            
            👤 根据您的身体状况：
            - 年龄：[年龄]岁
            - BMI：[BMI] ([BMI类型])
            
            ⚡️ 推荐难度：[入门/进阶]
            ⏱️ 建议时长：[X]秒
            
            🤸 推荐动作：
            
            1️⃣ [动作名称] ([持续时间]秒)
            📝 做法：[详细说明]
            ⚠️ 注意：[注意事项]
            
            2️⃣ [动作名称] ([持续时间]秒)
            📝 做法：[详细说明]
            ⚠️ 注意：[注意事项]
            
            3️⃣ [动作名称] ([持续时间]秒)
            📝 做法：[详细说明]
            ⚠️ 注意：[注意事项]
            
            💡 温馨提示：[个性化建议]
            """;
    }

    /**
     * 构建用户提示词
     */
    private String buildUserPrompt(PromptRequest request) {
        StringBuilder prompt = new StringBuilder();

        prompt.append("请为以下用户生成微运动建议：\n\n");
        prompt.append("【身体部位】").append(request.getBodyPart()).append("\n");
        prompt.append("【当前姿态】").append(request.getPostureInfo()).append("\n");
        prompt.append("【用户信息】\n");

        Map<String, Object> userInfo = request.getUserInfo();
        if (userInfo != null && !userInfo.isEmpty()) {
            // 提取关键信息并格式化
            extractAndFormatUserInfo(userInfo, prompt);
        } else {
            prompt.append("  - 无特定用户信息\n");
        }

        return prompt.toString();
    }

    /**
     * 提取和格式化用户信息
     */
    private void extractAndFormatUserInfo(Map<String, Object> userInfo, StringBuilder prompt) {
        // 按重要性排序显示用户信息
        String[] importantKeys = {"age", "gender", "height", "weight", "bmi", "bmi_type"};

        for (String key : importantKeys) {
            if (userInfo.containsKey(key) && userInfo.get(key) != null) {
                String value = userInfo.get(key).toString();
                String displayKey = getDisplayName(key);
                prompt.append("  - ").append(displayKey).append(": ").append(value).append("\n");
            }
        }

        // 显示其他可能有用的信息
        for (Map.Entry<String, Object> entry : userInfo.entrySet()) {
            String key = entry.getKey();
            // 跳过已显示的和敏感信息
            if (!Arrays.asList(importantKeys).contains(key)
                    && !key.equals("password")
                    && !key.equals("phone")
                    && !key.equals("email")
                    && entry.getValue() != null) {
                prompt.append("  - ").append(getDisplayName(key)).append(": ").append(entry.getValue()).append("\n");
            }
        }
    }

    /**
     * 获取字段的显示名称
     */
    private String getDisplayName(String key) {
        Map<String, String> displayNames = new HashMap<>();
        displayNames.put("age", "年龄");
        displayNames.put("gender", "性别");
        displayNames.put("height", "身高(cm)");
        displayNames.put("weight", "体重(kg)");
        displayNames.put("bmi", "BMI");
        displayNames.put("bmi_type", "BMI类型");
        displayNames.put("remind_enabled", "提醒开启");
        displayNames.put("remind_interval", "提醒间隔(分钟)");

        return displayNames.getOrDefault(key, key);
    }

    /**
     * 调用DeepSeek API
     */
    private DeepSeekResponse callDeepSeekAPI(String systemPrompt, String userPrompt) {
        // 设置请求头
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("Authorization", "Bearer " + apiKey);

        // 构建消息列表
        List<DeepSeekRequest.Message> messages = Arrays.asList(
                new DeepSeekRequest.Message("system", systemPrompt),
                new DeepSeekRequest.Message("user", userPrompt)
        );

        // 构建请求体
        DeepSeekRequest request = new DeepSeekRequest();
        request.setModel(model);
        request.setMessages(messages);
        request.setStream(false);
        request.setTemperature(temperature);
        request.setMaxTokens(maxTokens);

        log.info("调用DeepSeek API - model: {}, maxTokens: {}, temperature: {}",
                model, maxTokens, temperature);

        // 发送请求
        HttpEntity<DeepSeekRequest> entity = new HttpEntity<>(request, headers);

        long startTime = System.currentTimeMillis();
        ResponseEntity<DeepSeekResponse> response = restTemplate.exchange(
                apiUrl,
                HttpMethod.POST,
                entity,
                DeepSeekResponse.class
        );
        long endTime = System.currentTimeMillis();

        log.info("DeepSeek API调用完成 - 耗时: {}ms, 状态码: {}",
                (endTime - startTime), response.getStatusCode());

        return response.getBody();
    }

    /**
     * 解析API响应
     */
    private PromptResponse parseResponse(DeepSeekResponse apiResponse, PromptRequest originalRequest) {
        if (apiResponse == null || apiResponse.getChoices() == null || apiResponse.getChoices().isEmpty()) {
            log.error("API返回无效响应: {}", apiResponse);
            throw new RuntimeException("API返回无效响应");
        }

        // 获取生成的提示词
        String promptText = apiResponse.getChoices().get(0).getMessage().getContent();
        log.debug("生成的提示词: {}", promptText);

        // 根据用户信息推荐运动时长
        Integer duration = recommendDuration(originalRequest.getUserInfo());

        // 根据BMI和年龄推荐难度
        String difficulty = recommendDifficulty(originalRequest.getUserInfo());

        // 构建API使用情况
        PromptResponse.ApiUsage usage = null;
        if (apiResponse.getUsage() != null) {
            usage = PromptResponse.ApiUsage.builder()
                    .promptTokens(apiResponse.getUsage().getPromptTokens())
                    .completionTokens(apiResponse.getUsage().getCompletionTokens())
                    .totalTokens(apiResponse.getUsage().getTotalTokens())
                    .build();
        }

        return PromptResponse.builder()
                .promptText(promptText)
                .suggestedDuration(duration)
                .difficultyLevel(difficulty)
                .apiUsage(usage)
                .status("success")
                .build();
    }

    /**
     * 根据用户信息推荐运动时长
     */
    private Integer recommendDuration(Map<String, Object> userInfo) {
        if (userInfo == null || userInfo.isEmpty()) {
            return defaultDuration;
        }

        int duration = defaultDuration;

        try {
            // 根据BMI调整运动时长
            if (userInfo.containsKey("bmi")) {
                double bmi = Double.parseDouble(userInfo.get("bmi").toString());
                if (bmi > 28) {
                    duration = 45;  // 肥胖：较短时间
                } else if (bmi < 18.5) {
                    duration = 45;   // 偏瘦：较短时间
                } else if (bmi > 24) {
                    duration = 60;   // 偏胖：中等时间
                }
            }

            // 根据年龄调整
            if (userInfo.containsKey("age")) {
                int age = Integer.parseInt(userInfo.get("age").toString());
                if (age > 60) {
                    duration = Math.min(duration, 45);  // 老年人：不超过45秒
                } else if (age < 18) {
                    duration = Math.min(duration, 45);  // 未成年人：不超过45秒
                }
            }

            // 根据体重调整
            if (userInfo.containsKey("weight")) {
                double weight = Double.parseDouble(userInfo.get("weight").toString());
                if (weight > 90) {  // 体重过重
                    duration = Math.min(duration, 50);
                }
            }

        } catch (NumberFormatException e) {
            log.warn("解析用户数据失败，使用默认时长", e);
        }

        return duration;
    }

    /**
     * 根据用户信息推荐难度级别
     */
    private String recommendDifficulty(Map<String, Object> userInfo) {
        if (userInfo == null || userInfo.isEmpty()) {
            return "入门";
        }

        boolean hasHealthIssue = false;
        boolean isFit = true;

        try {
            // 根据BMI判断
            if (userInfo.containsKey("bmi")) {
                double bmi = Double.parseDouble(userInfo.get("bmi").toString());
                if (bmi > 28 || bmi < 18.5) {
                    hasHealthIssue = true;
                } else if (bmi >= 20 && bmi <= 24) {
                    isFit = true;
                }
            }

            // 根据年龄判断
            if (userInfo.containsKey("age")) {
                int age = Integer.parseInt(userInfo.get("age").toString());
                if (age > 60 || age < 18) {
                    hasHealthIssue = true;
                } else if (age >= 18 && age <= 40) {
                    isFit = isFit && true;
                }
            }

            // 根据BMI类型判断
            if (userInfo.containsKey("bmi_type")) {
                String bmiType = userInfo.get("bmi_type").toString();
                if (bmiType.contains("肥胖") || bmiType.contains("偏瘦")) {
                    hasHealthIssue = true;
                }
            }

        } catch (NumberFormatException e) {
            log.warn("解析用户数据失败，使用默认难度", e);
        }

        if (hasHealthIssue) {
            return "入门";
        } else if (isFit) {
            return "进阶";
        } else {
            return "入门";
        }
    }
}