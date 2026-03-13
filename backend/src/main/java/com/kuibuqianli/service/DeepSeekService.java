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
    private final VideoService videoService;

    public DeepSeekService(VideoService videoService) {
        this.restTemplate = new RestTemplate();
        this.objectMapper = new ObjectMapper();
        this.videoService = videoService;
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
            List<String> availableVideos = videoService.getAvailableVideos();
            if (availableVideos == null || availableVideos.isEmpty()) {
                return PromptResponse.error("当前视频库为空，暂时无法生成可播放的微运动方案");
            }

            String systemPrompt = buildSystemPrompt(availableVideos);

            // 2. 构建用户提示词
            String userPrompt = buildUserPrompt(request, availableVideos);

            log.debug("系统提示词: {}", systemPrompt);
            log.debug("用户提示词: {}", userPrompt);

            // 3. 调用DeepSeek API
            DeepSeekResponse apiResponse = callDeepSeekAPI(systemPrompt, userPrompt);

            // 4. 解析响应并生成返回结果
            PromptResponse response = parseResponse(apiResponse, request, availableVideos);

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
    private String buildSystemPrompt(List<String> availableVideos) {
        String videoRule = buildVideoRule(availableVideos);
        return ("""
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
            9. 动作名称必须严格从系统提供的视频动作库中选择，不能自创、改写、扩写，也不能输出视频库以外的动作
            10. 只返回 JSON，不要返回 markdown，不要写 ```json，不要添加任何解释文字
            
            【JSON格式】
            {
              "title": "针对颈部的微运动方案",
              "overview": "一句简短说明，告诉用户这套动作适合什么情况",
              "difficulty_level": "入门或进阶",
              "suggested_duration": 60,
              "actions": [
                {
                  "name": "动作名称，必须来自视频动作库",
                  "seconds": 20,
                  "instruction": "一句清晰做法",
                  "warning": "一句注意事项"
                }
              ],
              "tip": "一句个性化提醒"
            }
            """ + "\n\n" + videoRule);
    }

    /**
     * 构建用户提示词
     */
    private String buildUserPrompt(PromptRequest request, List<String> availableVideos) {
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

        prompt.append("\n【可选动作库】\n");
        List<String> actionNames = toActionNames(availableVideos);
        if (actionNames.isEmpty()) {
            prompt.append("  - 当前没有可用视频动作，请返回最基础的通用部位放松建议\n");
        } else {
            for (String actionName : actionNames) {
                prompt.append("  - ").append(actionName).append("\n");
            }
            prompt.append("\n请严格只从上面的动作库里选择 2-3 个动作作为推荐动作名称。\n");
        }

        return prompt.toString();
    }

    private String buildVideoRule(List<String> availableVideos) {
        List<String> actionNames = toActionNames(availableVideos);
        if (actionNames.isEmpty()) {
            return "【视频动作库】当前为空。";
        }
        return "【视频动作库】你只能从以下动作名称中选择：" + String.join("、", actionNames);
    }

    private List<String> toActionNames(List<String> availableVideos) {
        if (availableVideos == null || availableVideos.isEmpty()) {
            return Collections.emptyList();
        }
        return availableVideos.stream()
                .map(this::normalizeVideoName)
                .filter(name -> !name.isEmpty())
                .distinct()
                .toList();
    }

    private String normalizeVideoName(String filename) {
        if (filename == null) {
            return "";
        }
        String name = filename.replaceFirst("\\.[^.]+$", "");
        name = name.replace('_', ' ').replace('-', ' ').trim();
        return name;
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
    private PromptResponse parseResponse(DeepSeekResponse apiResponse, PromptRequest originalRequest, List<String> availableVideos) {
        if (apiResponse == null || apiResponse.getChoices() == null || apiResponse.getChoices().isEmpty()) {
            log.error("API返回无效响应: {}", apiResponse);
            throw new RuntimeException("API返回无效响应");
        }

        // 获取生成的提示词
        String rawContent = sanitizeAiText(apiResponse.getChoices().get(0).getMessage().getContent());
        Map<String, Object> content = parseAiJsonContent(rawContent);
        List<PromptResponse.ActionItem> actions = buildActionItems(content.get("actions"), availableVideos, originalRequest.getBodyPart());

        String title = stringValue(content.get("title"), "针对" + originalRequest.getBodyPart() + "的微运动方案");
        String overview = stringValue(content.get("overview"), "基于当前状态生成的微运动建议");
        String tip = stringValue(content.get("tip"), "动作过程中如有明显不适，请立即停止。");
        String promptText = buildReadablePromptText(title, overview, actions, tip);
        log.debug("生成的结构化提示词: {}", promptText);

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
                .title(title)
                .overview(overview)
                .promptText(promptText)
                .suggestedDuration(duration)
                .difficultyLevel(difficulty)
                .actions(actions)
                .tip(tip)
                .apiUsage(usage)
                .status("success")
                .build();
    }

    private String sanitizeAiText(String text) {
        if (text == null) {
            return "";
        }
        return text.replace('*', ' ');
    }

    private Map<String, Object> parseAiJsonContent(String rawContent) {
        String cleaned = rawContent == null ? "" : rawContent.trim();
        cleaned = cleaned.replace("```json", "").replace("```", "").trim();
        try {
            return objectMapper.readValue(cleaned, Map.class);
        } catch (Exception e) {
            log.warn("AI 返回的不是合法 JSON，将回退为兜底结构。内容: {}", rawContent);
            Map<String, Object> fallback = new HashMap<>();
            fallback.put("title", "微运动方案");
            fallback.put("overview", cleaned);
            fallback.put("actions", Collections.emptyList());
            fallback.put("tip", "请结合视频指导安全完成动作。");
            return fallback;
        }
    }

    private List<PromptResponse.ActionItem> buildActionItems(Object actionsObject, List<String> availableVideos, String bodyPart) {
        List<String> allowedActions = toActionNames(availableVideos);
        List<String> preferredActions = pickPreferredActions(allowedActions, bodyPart);
        List<PromptResponse.ActionItem> result = new ArrayList<>();

        if (actionsObject instanceof List<?> actionList) {
            int replacementIndex = 0;
            for (Object item : actionList) {
                if (!(item instanceof Map<?, ?> actionMap)) {
                    continue;
                }
                String currentAction = stringValue(actionMap.get("name"), "");
                String resolvedAction = resolveAllowedAction(currentAction, allowedActions, preferredActions, replacementIndex);
                if (!resolvedAction.isEmpty()) {
                    replacementIndex++;
                }
                result.add(PromptResponse.ActionItem.builder()
                        .name(resolvedAction)
                        .seconds(intValue(actionMap.get("seconds"), 20))
                        .instruction(stringValue(actionMap.get("instruction"), "请按照视频动作缓慢完成。"))
                        .warning(stringValue(actionMap.get("warning"), "如果感到不适，请立即停止。"))
                        .build());
            }
        }

        if (result.isEmpty()) {
            int index = 0;
            for (String action : preferredActions.isEmpty() ? allowedActions : preferredActions) {
                result.add(PromptResponse.ActionItem.builder()
                        .name(action)
                        .seconds(20)
                        .instruction("请跟随视频动作缓慢完成。")
                        .warning("动作保持轻柔，出现不适请立即停止。")
                        .build());
                index++;
                if (index >= 3) {
                    break;
                }
            }
        }

        return result;
    }

    private String buildReadablePromptText(String title, String overview, List<PromptResponse.ActionItem> actions, String tip) {
        StringBuilder builder = new StringBuilder();
        builder.append(title).append("\n");
        builder.append(overview).append("\n");
        for (int i = 0; i < actions.size(); i++) {
            PromptResponse.ActionItem action = actions.get(i);
            builder.append(i + 1).append(". ")
                    .append(action.getName())
                    .append(" (")
                    .append(action.getSeconds())
                    .append("秒)\n")
                    .append("做法：")
                    .append(action.getInstruction())
                    .append("\n注意：")
                    .append(action.getWarning())
                    .append("\n");
        }
        builder.append("提示：").append(tip);
        return builder.toString().trim();
    }

    private String stringValue(Object value, String fallback) {
        if (value == null) {
            return fallback;
        }
        String text = value.toString().trim();
        return text.isEmpty() ? fallback : text;
    }

    private List<String> pickPreferredActions(List<String> allowedActions, String bodyPart) {
        if (bodyPart == null || bodyPart.isBlank()) {
            return allowedActions;
        }
        List<String> matched = allowedActions.stream()
                .filter(name -> normalizeForCompare(name).contains(normalizeForCompare(bodyPart)))
                .toList();
        return matched.isEmpty() ? allowedActions : matched;
    }

    private String resolveAllowedAction(String currentAction, List<String> allowedActions, List<String> preferredActions, int replacementIndex) {
        if (allowedActions.isEmpty()) {
            return currentAction == null ? "" : currentAction;
        }
        for (String allowed : allowedActions) {
            if (normalizeForCompare(allowed).equals(normalizeForCompare(currentAction))) {
                return allowed;
            }
        }

        for (String allowed : allowedActions) {
            String normalizedAllowed = normalizeForCompare(allowed);
            String normalizedCurrent = normalizeForCompare(currentAction);
            if (normalizedAllowed.contains(normalizedCurrent) || normalizedCurrent.contains(normalizedAllowed)) {
                return allowed;
            }
        }

        List<String> source = preferredActions.isEmpty() ? allowedActions : preferredActions;
        return source.get(Math.min(replacementIndex, source.size() - 1));
    }

    private int intValue(Object value, int fallback) {
        if (value == null) {
            return fallback;
        }
        if (value instanceof Number number) {
            return number.intValue();
        }
        try {
            return Integer.parseInt(value.toString());
        } catch (NumberFormatException e) {
            return fallback;
        }
    }

    private String normalizeForCompare(String value) {
        if (value == null) {
            return "";
        }
        return value.replaceAll("\\s+", "").replaceAll("[^\\p{IsHan}A-Za-z0-9]", "").toLowerCase(Locale.ROOT);
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
