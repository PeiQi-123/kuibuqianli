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
    private final PreferenceLearningService preferenceLearningService;

    public DeepSeekService(VideoService videoService, PreferenceLearningService preferenceLearningService) {
        this.restTemplate = new RestTemplate();
        this.objectMapper = new ObjectMapper();
        this.videoService = videoService;
        this.preferenceLearningService = preferenceLearningService;
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
            request.setUserInfo(enrichUserInfo(request.getUserInfo()));
            Long userId = extractUserId(request.getUserInfo());
            List<Map<String, Object>> candidateActions = videoService.recommendActionCandidates(
                    userId,
                    request.getBodyPart(),
                    request.getUserInfo(),
                    8
            );

            // 1. 构建系统提示词
            String systemPrompt = buildSystemPrompt(candidateActions);

            // 2. 构建用户提示词
            String userPrompt = buildUserPrompt(request, candidateActions);

            log.debug("系统提示词: {}", systemPrompt);
            log.debug("用户提示词: {}", userPrompt);

            // 3. 调用DeepSeek API
            DeepSeekResponse apiResponse = callDeepSeekAPI(systemPrompt, userPrompt);

            // 4. 解析响应并生成返回结果
            PromptResponse response = parseResponse(apiResponse, request, candidateActions);

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

    private Map<String, Object> enrichUserInfo(Map<String, Object> userInfo) {
        Map<String, Object> safeUserInfo = userInfo == null ? new HashMap<>() : new HashMap<>(userInfo);
        Long userId = extractUserId(safeUserInfo);
        if (userId == null) {
            return safeUserInfo;
        }
        return preferenceLearningService.enrichUserInfo(userId, safeUserInfo);
    }

    private Long extractUserId(Map<String, Object> userInfo) {
        Object idValue = userInfo.get("user_id");
        if (idValue == null) {
            idValue = userInfo.get("id");
        }
        if (idValue == null) {
            return null;
        }
        try {
            return Long.parseLong(idValue.toString());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /**
     * 构建系统提示词
     */
    private String buildSystemPrompt(List<Map<String, Object>> candidateActions) {
        String candidateConstraint = candidateActions == null || candidateActions.isEmpty()
                ? "14. 当前没有候选动作池时，可自行生成安全且通用的动作名称"
                : "14. 如果提供候选动作池，优先从候选动作池中选择动作，尽量不要输出池外动作；如果必须输出池外动作，也要保证动作安全、通用且可检索";
        return """
            你是一个专业的微运动健康顾问。请根据用户的身体部位、当前姿态和个人信息，
            生成简短、实用、安全的微运动建议。
            
            【要求】
            1. 运动建议要简单易行，可以在办公位或家里完成，不需要特殊设备
            2. 考虑用户的BMI和年龄，避免不适合的运动
            3. 每次建议包含2-3个微运动动作
            4. 每个动作要说明：动作名称、具体做法、持续时间、注意事项
            5. 用友好、鼓励的语气，像私人教练一样
            6. 返回格式要清晰易读，不要使用 markdown
            7. 如果用户有某些健康禁忌（如腰伤、高血压等），要特别提醒
            8. 结合用户的当前姿态给出针对性建议
            9. 动作名称应简洁、自然、通用，便于后续检索对应指导视频
            10. 只返回 JSON，不要返回 markdown，不要写 ```json，不要添加任何解释文字
            11. 如果用户存在显式偏好或系统学习出的偏好，优先让推荐结果与这些偏好保持一致
            12. 如果用户最近反馈显示“太难”，优先降低动作复杂度和节奏；如果显示“太简单”，优先适当增加挑战度
            13. 优先选择与目标部位、偏好运动类型、偏好时长、偏好难度一致的动作组合
            %s
            
            【JSON格式】
            {
              "title": "针对颈部的微运动方案",
              "overview": "一句简短说明，告诉用户这套动作适合什么情况",
              "difficulty_level": "入门或进阶",
              "suggested_duration": 60,
              "actions": [
                {
                  "name": "候选动作池中的标准动作名称",
                  "rerank_score": 0.92,
                  "seconds": 20,
                  "instruction": "一句清晰做法",
                  "warning": "一句注意事项",
                  "selection_reason": "为什么最终选择这个动作"
                }
              ],
              "candidate_ranking": [
                {
                  "name": "候选动作池中的标准动作名称",
                  "rerank_score": 0.92,
                  "selected": true,
                  "reason": "动作与目标部位、偏好和安全约束的匹配原因"
                }
              ],
              "tip": "一句个性化提醒"
            }
            """.formatted(candidateConstraint);
    }

    /**
     * 构建用户提示词
     */
    private String buildUserPrompt(PromptRequest request, List<Map<String, Object>> candidateActions) {
        StringBuilder prompt = new StringBuilder();

        prompt.append("请为以下用户生成微运动建议：\n\n");
        prompt.append("【身体部位】").append(request.getBodyPart()).append("\n");
        prompt.append("【当前姿态】").append(request.getPostureInfo()).append("\n");
        prompt.append("【用户信息】\n");

        Map<String, Object> userInfo = request.getUserInfo();
        if (userInfo != null && !userInfo.isEmpty()) {
            // 提取关键信息并格式化
            extractAndFormatUserInfo(userInfo, prompt);
            appendPreferenceGuidance(userInfo, prompt);
            appendCandidateGuidance(candidateActions, prompt);
        } else {
            prompt.append("  - 无特定用户信息\n");
        }

        return prompt.toString();
    }

    private void appendPreferenceGuidance(Map<String, Object> userInfo, StringBuilder prompt) {
        List<String> preferredBodyParts = extractStringList(userInfo.get("preferred_body_parts"));
        List<String> preferredSportTypes = extractStringList(userInfo.get("preferred_sport_types"));
        List<String> preferredDurations = extractStringList(userInfo.get("preferred_durations"));
        List<String> preferredDifficulty = extractStringList(userInfo.get("preferred_difficulty"));
        List<String> explicitSpecialCases = extractStringList(userInfo.get("explicit_special_cases"));
        String learningSummary = stringValue(userInfo.get("preference_learning_summary"), "");

        prompt.append("\n【推荐策略约束】\n");
        if (!preferredBodyParts.isEmpty()) {
            prompt.append("  - 尽量优先覆盖这些偏好部位: ").append(String.join("、", preferredBodyParts)).append("\n");
        }
        if (!preferredSportTypes.isEmpty()) {
            prompt.append("  - 尽量优先选择这些偏好类型: ").append(String.join("、", preferredSportTypes)).append("\n");
        }
        if (!preferredDurations.isEmpty()) {
            prompt.append("  - 推荐总时长尽量贴近: ").append(String.join("、", preferredDurations)).append("\n");
        }
        if (!preferredDifficulty.isEmpty()) {
            prompt.append("  - 推荐难度尽量贴近: ").append(String.join("、", preferredDifficulty)).append("\n");
        }
        if (!explicitSpecialCases.isEmpty()) {
            prompt.append("  - 需要规避的特殊情况/禁忌: ").append(String.join("、", explicitSpecialCases)).append("\n");
            prompt.append("  - 优先使用舒缓、安全、低冲击动作，避免强刺激和高风险动作\n");
        }
        if (!learningSummary.isBlank()) {
            prompt.append("  - 系统动态学习结论: ").append(learningSummary).append("\n");
        }
    }

    private void appendCandidateGuidance(List<Map<String, Object>> candidateActions, StringBuilder prompt) {
        if (candidateActions == null || candidateActions.isEmpty()) {
            return;
        }
        prompt.append("\n【候选动作池（召回+排序结果）】\n");
        for (int index = 0; index < candidateActions.size(); index++) {
            Map<String, Object> candidate = candidateActions.get(index);
            String actionName = stringValue(candidate.get("action_name"), "");
            String category = stringValue(candidate.get("category"), "");
            String score = String.valueOf(candidate.getOrDefault("score", ""));
            List<String> reasons = extractStringList(candidate.get("reasons"));
            prompt.append("  ")
                    .append(index + 1)
                    .append(". ")
                    .append(actionName);
            if (!category.isBlank()) {
                prompt.append("（").append(category).append("）");
            }
            if (!score.isBlank()) {
                prompt.append(" - 分数 ").append(score);
            }
            if (!reasons.isEmpty()) {
                prompt.append(" - ").append(String.join("、", reasons));
            }
            prompt.append("\n");
        }
        prompt.append("【动作选择要求】\n");
        prompt.append("  - 优先从候选动作池前列选择 2-3 个动作\n");
        prompt.append("  - 尽量保持动作类别多样，避免所有动作都属于同一种模式\n");
        prompt.append("  - 对近期负反馈多、最近反复出现的动作降低优先级\n");
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

        appendPreferenceLine(prompt, "preferred_body_parts", userInfo.get("preferred_body_parts"));
        appendPreferenceLine(prompt, "preferred_sport_types", userInfo.get("preferred_sport_types"));
        appendPreferenceLine(prompt, "preferred_scenes", userInfo.get("preferred_scenes"));
        appendPreferenceLine(prompt, "preferred_durations", userInfo.get("preferred_durations"));
        appendPreferenceLine(prompt, "preferred_pace", userInfo.get("preferred_pace"));
        appendPreferenceLine(prompt, "preferred_difficulty", userInfo.get("preferred_difficulty"));
        if (userInfo.get("preference_learning_summary") != null) {
            prompt.append("  - 动态学习结论: ")
                    .append(userInfo.get("preference_learning_summary"))
                    .append("\n");
        }

        // 显示其他可能有用的信息
        for (Map.Entry<String, Object> entry : userInfo.entrySet()) {
            String key = entry.getKey();
            // 跳过已显示的和敏感信息
            if (!Arrays.asList(importantKeys).contains(key)
                    && !key.equals("password")
                    && !key.equals("phone")
                    && !key.equals("email")
                    && !key.equals("user_id")
                    && !key.startsWith("preferred_")
                    && !key.endsWith("_preferences")
                    && !key.equals("preference_learning_summary")
                    && entry.getValue() != null) {
                prompt.append("  - ").append(getDisplayName(key)).append(": ").append(entry.getValue()).append("\n");
            }
        }
    }

    private void appendPreferenceLine(StringBuilder prompt, String key, Object value) {
        if (value instanceof List<?> list && !list.isEmpty()) {
            String joined = list.stream().map(String::valueOf).collect(java.util.stream.Collectors.joining("、"));
            prompt.append("  - ").append(getDisplayName(key)).append(": ").append(joined).append("\n");
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
        displayNames.put("preferred_body_parts", "动态学习偏好部位");
        displayNames.put("preferred_sport_types", "动态学习偏好运动类型");
        displayNames.put("preferred_scenes", "动态学习偏好场景");
        displayNames.put("preferred_durations", "动态学习偏好时长");
        displayNames.put("preferred_pace", "动态学习偏好节奏");
        displayNames.put("preferred_difficulty", "动态学习建议难度");
        displayNames.put("explicit_special_cases", "特殊情况/禁忌");

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
    private PromptResponse parseResponse(
            DeepSeekResponse apiResponse,
            PromptRequest originalRequest,
            List<Map<String, Object>> candidateActions
    ) {
        if (apiResponse == null || apiResponse.getChoices() == null || apiResponse.getChoices().isEmpty()) {
            log.error("API返回无效响应: {}", apiResponse);
            throw new RuntimeException("API返回无效响应");
        }

        // 获取生成的提示词
        String rawContent = sanitizeAiText(apiResponse.getChoices().get(0).getMessage().getContent());
        Map<String, Object> content = parseAiJsonContent(rawContent);
        List<String> allowedActions = extractCandidateActionNames(candidateActions);
        List<PromptResponse.ActionItem> actions = buildActionItems(
                content.get("actions"),
                originalRequest.getBodyPart(),
                originalRequest.getUserInfo(),
                allowedActions
        );

        String title = stringValue(content.get("title"), "针对" + originalRequest.getBodyPart() + "的微运动方案");
        String overview = stringValue(content.get("overview"), "基于当前状态生成的微运动建议");
        String tip = stringValue(content.get("tip"), "动作过程中如有明显不适，请立即停止。");
        String promptText = buildReadablePromptText(title, overview, actions, tip);
        log.debug("生成的结构化提示词: {}", promptText);

        // 根据用户信息推荐运动时长
        Integer duration = recommendDuration(originalRequest.getUserInfo());

        // 根据BMI和年龄推荐难度
        String difficulty = recommendDifficulty(originalRequest.getUserInfo());

        Map<String, Object> preferenceApplied = buildPreferenceApplied(
                originalRequest,
                actions,
                duration,
                difficulty
        );
        List<Map<String, Object>> recommendationTrace = buildRecommendationTrace(
                candidateActions,
                content.get("candidate_ranking"),
                actions
        );

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
                .preferenceApplied(preferenceApplied)
                .recommendationTrace(recommendationTrace)
                .apiUsage(usage)
                .status("success")
                .build();
    }

    private Map<String, Object> buildPreferenceApplied(
            PromptRequest request,
            List<PromptResponse.ActionItem> actions,
            Integer duration,
            String difficulty
    ) {
        Map<String, Object> result = new LinkedHashMap<>();
        Map<String, Object> userInfo = request.getUserInfo();
        if (userInfo == null || userInfo.isEmpty()) {
            result.put("matched", false);
            result.put("summary", "本次推荐主要基于当前选择生成，暂未应用历史偏好。");
            return result;
        }

        List<String> matchedItems = new ArrayList<>();
        List<String> preferredBodyParts = extractStringList(userInfo.get("preferred_body_parts"));
        List<String> preferredSportTypes = extractStringList(userInfo.get("preferred_sport_types"));
        List<String> preferredDurations = extractStringList(userInfo.get("preferred_durations"));
        List<String> preferredDifficulty = extractStringList(userInfo.get("preferred_difficulty"));

        if (!preferredBodyParts.isEmpty() && preferredBodyParts.contains(request.getBodyPart())) {
            matchedItems.add("目标部位匹配了你的偏好：" + request.getBodyPart());
        }

        List<String> actionNames = actions.stream().map(PromptResponse.ActionItem::getName).toList();
        List<String> matchedActionPreferences = preferredSportTypes.stream()
                .filter(type -> actionNames.stream().anyMatch(action -> matchesAnyPreference(action, List.of(type))))
                .toList();
        if (!matchedActionPreferences.isEmpty()) {
            matchedItems.add("动作类型贴合你的偏好：" + String.join("、", matchedActionPreferences));
        }

        String durationText = duration == null ? "" : Math.max(1, Math.round(duration / 60f)) + "分钟";
        if (!durationText.isBlank() && preferredDurations.stream().anyMatch(item -> item.contains(durationText) || durationText.contains(item.replace("约", "")))) {
            matchedItems.add("推荐时长贴近你的偏好：" + durationText);
        }

        if (!preferredDifficulty.isEmpty() && preferredDifficulty.stream().anyMatch(item -> difficultyMatches(item, difficulty))) {
            matchedItems.add("推荐难度贴近你的偏好：" + difficulty);
        }

        String learningSummary = stringValue(userInfo.get("preference_learning_summary"), "");
        if (!learningSummary.isBlank()) {
            matchedItems.add("已参考系统学习结论进行推荐调整");
        }

        result.put("matched", !matchedItems.isEmpty());
        result.put("matched_items", matchedItems);
        result.put("summary", matchedItems.isEmpty()
                ? "本次推荐主要基于当前选择生成，暂未命中明显的历史偏好。"
                : "本次推荐已结合你的历史偏好进行调整。");
        return result;
    }

    private boolean difficultyMatches(String preferredDifficulty, String currentDifficulty) {
        String preferred = preferredDifficulty == null ? "" : preferredDifficulty;
        String current = currentDifficulty == null ? "" : currentDifficulty;
        if (preferred.contains("零基础") || preferred.contains("入门")) {
            return current.contains("入门");
        }
        if (preferred.contains("有难度") || preferred.contains("进阶")) {
            return current.contains("进阶");
        }
        return normalizeForCompare(preferred).contains(normalizeForCompare(current))
                || normalizeForCompare(current).contains(normalizeForCompare(preferred));
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
            fallback.put("tip", "请根据自身状态轻柔完成动作，如有不适请立即停止。");
            return fallback;
        }
    }

    private List<PromptResponse.ActionItem> buildActionItems(
            Object actionsObject,
            String bodyPart,
            Map<String, Object> userInfo,
            List<String> allowedActions
    ) {
        List<PromptResponse.ActionItem> result = new ArrayList<>();
        Set<String> usedActionNames = new LinkedHashSet<>();
        List<String> preferredActions = allowedActions == null ? Collections.emptyList() : allowedActions;

        if (actionsObject instanceof List<?> actionList) {
            for (Object item : actionList) {
                if (!(item instanceof Map<?, ?> actionMap)) {
                    continue;
                }
                String resolvedAction = stringValue(actionMap.get("name"), suggestFallbackActionName(bodyPart, result.size()));
                resolvedAction = resolveAllowedAction(resolvedAction, preferredActions, preferredActions, result.size());
                resolvedAction = ensureDistinctActionName(resolvedAction, usedActionNames, preferredActions, result.size(), bodyPart);
                usedActionNames.add(resolvedAction);
                result.add(PromptResponse.ActionItem.builder()
                        .name(resolvedAction)
                        .seconds(intValue(actionMap.get("seconds"), 20))
                        .instruction(stringValue(actionMap.get("instruction"), "请缓慢完成动作，保持呼吸自然。"))
                        .warning(stringValue(actionMap.get("warning"), "如果感到不适，请立即停止。"))
                        .rerankScore(doubleValue(actionMap.get("rerank_score")))
                        .selectionReason(stringValue(actionMap.get("selection_reason"), ""))
                        .build());
            }
        }

        if (result.isEmpty()) {
            for (int index = 0; index < 3; index++) {
                String fallbackAction = ensureDistinctActionName(
                        suggestFallbackActionName(bodyPart, index),
                        usedActionNames,
                        preferredActions,
                        index,
                        bodyPart
                );
                usedActionNames.add(fallbackAction);
                result.add(PromptResponse.ActionItem.builder()
                        .name(fallbackAction)
                        .seconds(20)
                        .instruction("请缓慢完成动作，保持身体放松和呼吸稳定。")
                        .warning("动作保持轻柔，出现不适请立即停止。")
                        .rerankScore(null)
                        .selectionReason("")
                        .build());
            }
        }

        return result;
    }

    private List<String> extractCandidateActionNames(List<Map<String, Object>> candidateActions) {
        if (candidateActions == null || candidateActions.isEmpty()) {
            return Collections.emptyList();
        }
        return candidateActions.stream()
                .map(item -> stringValue(item.get("action_name"), ""))
                .filter(name -> !name.isBlank())
                .distinct()
                .toList();
    }

    private List<Map<String, Object>> buildRecommendationTrace(
            List<Map<String, Object>> candidateActions,
            Object candidateRankingObject,
            List<PromptResponse.ActionItem> selectedActions
    ) {
        if (candidateActions == null || candidateActions.isEmpty()) {
            return Collections.emptyList();
        }

        Map<String, Map<String, Object>> llmRanking = parseCandidateRanking(candidateRankingObject);
        Map<String, Integer> selectedOrder = new HashMap<>();
        Map<String, PromptResponse.ActionItem> selectedActionMap = new HashMap<>();
        for (int index = 0; index < selectedActions.size(); index++) {
            PromptResponse.ActionItem action = selectedActions.get(index);
            selectedOrder.put(normalizeForCompare(action.getName()), index + 1);
            selectedActionMap.put(normalizeForCompare(action.getName()), action);
        }

        List<Double> recallScores = candidateActions.stream()
                .map(item -> doubleValue(item.get("score")))
                .filter(Objects::nonNull)
                .toList();
        double minRecall = recallScores.stream().mapToDouble(Double::doubleValue).min().orElse(0D);
        double maxRecall = recallScores.stream().mapToDouble(Double::doubleValue).max().orElse(1D);

        List<Map<String, Object>> trace = new ArrayList<>();
        for (int index = 0; index < candidateActions.size(); index++) {
            Map<String, Object> candidate = candidateActions.get(index);
            String actionName = stringValue(candidate.get("action_name"), "");
            String normalizedName = normalizeForCompare(actionName);
            Double recallScore = doubleValue(candidate.get("score"));
            double normalizedRecall = normalizeScore(recallScore, minRecall, maxRecall);
            Map<String, Object> llmInfo = llmRanking.getOrDefault(normalizedName, Collections.emptyMap());
            PromptResponse.ActionItem selectedAction = selectedActionMap.get(normalizedName);

            Double rerankScore = doubleValue(llmInfo.get("rerank_score"));
            if (rerankScore == null && selectedAction != null) {
                rerankScore = selectedAction.getRerankScore();
            }
            rerankScore = normalizeUnitScore(rerankScore, index);

            String llmReason = stringValue(llmInfo.get("reason"), "");
            if (llmReason.isBlank() && selectedAction != null) {
                llmReason = stringValue(selectedAction.getSelectionReason(), "");
            }

            Integer selectedRank = selectedOrder.get(normalizedName);
            boolean selected = selectedRank != null;
            double finalScore = selected
                    ? (normalizedRecall * 0.4D) + (rerankScore * 0.6D)
                    : (normalizedRecall * 0.7D) + (rerankScore * 0.3D);

            Map<String, Object> item = new LinkedHashMap<>();
            item.put("action_name", actionName);
            item.put("category", stringValue(candidate.get("category"), ""));
            item.put("candidate_rank", index + 1);
            item.put("selected_rank", selectedRank);
            item.put("selected", selected);
            item.put("recall_score", recallScore);
            item.put("normalized_recall_score", roundScore(normalizedRecall));
            item.put("llm_rerank_score", roundScore(rerankScore));
            item.put("final_score", roundScore(finalScore));
            item.put("recall_reasons", candidate.getOrDefault("reasons", Collections.emptyList()));
            item.put("llm_reason", llmReason);
            trace.add(item);
        }

        trace.sort((left, right) -> Double.compare(
                doubleValue(right.get("final_score")) == null ? 0D : doubleValue(right.get("final_score")),
                doubleValue(left.get("final_score")) == null ? 0D : doubleValue(left.get("final_score"))
        ));
        return trace;
    }

    private Map<String, Map<String, Object>> parseCandidateRanking(Object candidateRankingObject) {
        if (!(candidateRankingObject instanceof List<?> rankingList)) {
            return Collections.emptyMap();
        }
        Map<String, Map<String, Object>> rankingMap = new HashMap<>();
        for (Object item : rankingList) {
            if (!(item instanceof Map<?, ?> rawMap)) {
                continue;
            }
            Map<String, Object> map = new HashMap<>();
            rawMap.forEach((key, value) -> map.put(String.valueOf(key), value));
            String actionName = stringValue(map.get("name"), "");
            if (!actionName.isBlank()) {
                rankingMap.put(normalizeForCompare(actionName), map);
            }
        }
        return rankingMap;
    }

    private double normalizeScore(Double value, double min, double max) {
        if (value == null) {
            return 0D;
        }
        if (Math.abs(max - min) < 1e-6) {
            return 1D;
        }
        return Math.max(0D, Math.min(1D, (value - min) / (max - min)));
    }

    private double normalizeUnitScore(Double score, int fallbackIndex) {
        if (score == null) {
            return Math.max(0.2D, 0.95D - (fallbackIndex * 0.08D));
        }
        if (score > 1D && score <= 100D) {
            return Math.max(0D, Math.min(1D, score / 100D));
        }
        return Math.max(0D, Math.min(1D, score));
    }

    private double roundScore(double score) {
        return Math.round(score * 1000D) / 1000D;
    }

    private String ensureDistinctActionName(
            String actionName,
            Set<String> usedActionNames,
            List<String> allowedActions,
            int replacementIndex,
            String bodyPart
    ) {
        if (!usedActionNames.contains(actionName)) {
            return actionName;
        }
        if (allowedActions != null) {
            for (String candidate : allowedActions) {
                if (!usedActionNames.contains(candidate)) {
                    return candidate;
                }
            }
        }
        String fallback = suggestFallbackActionName(bodyPart, replacementIndex + usedActionNames.size());
        if (!usedActionNames.contains(fallback)) {
            return fallback;
        }
        return fallback + (usedActionNames.size() + 1);
    }

    private String suggestFallbackActionName(String bodyPart, int index) {
        List<String> defaults = switch (bodyPart == null ? "" : bodyPart) {
            case "颈部", "头部" -> List.of("颈部侧屈拉伸", "颈部缓慢转动", "收下巴放松");
            case "肩部" -> List.of("肩部环绕", "耸肩放松", "肩颈拉伸");
            case "腰部" -> List.of("腰背伸展", "坐姿躯干转动", "骨盆轻摆放松");
            case "背部" -> List.of("扩胸运动", "坐姿含胸伸背", "肩胛内收放松");
            case "腿部" -> List.of("腿后侧拉伸", "踝关节环绕", "提踵放松");
            case "手腕" -> List.of("手腕环绕", "手指伸展", "前臂放松拉伸");
            default -> List.of("局部拉伸放松", "关节轻柔活动", "呼吸调整放松");
        };
        return defaults.get(Math.min(index, defaults.size() - 1));
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

    private List<String> pickPreferredActions(List<String> allowedActions, String bodyPart, Map<String, Object> userInfo) {
        if (allowedActions.isEmpty()) {
            return allowedActions;
        }
        return allowedActions.stream()
                .sorted((left, right) -> Double.compare(
                        scoreAction(right, bodyPart, userInfo),
                        scoreAction(left, bodyPart, userInfo)
                ))
                .distinct()
                .toList();
    }

    private double scoreAction(String actionName, String bodyPart, Map<String, Object> userInfo) {
        if (actionName == null || actionName.isBlank()) {
            return 0D;
        }

        double score = 1D;
        List<String> targetBodyParts = new ArrayList<>();
        if (bodyPart != null && !bodyPart.isBlank()) {
            targetBodyParts.add(bodyPart);
        }
        if (userInfo != null) {
            targetBodyParts.addAll(extractStringList(userInfo.get("preferred_body_parts")));
        }
        if (matchesAnyPreference(actionName, targetBodyParts)) {
            score += 3D;
        }

        List<String> sportTypes = userInfo == null ? Collections.emptyList() : extractStringList(userInfo.get("preferred_sport_types"));
        if (matchesAnyPreference(actionName, sportTypes)) {
            score += 2D;
        }

        List<String> difficulty = userInfo == null ? Collections.emptyList() : extractStringList(userInfo.get("preferred_difficulty"));
        if (!difficulty.isEmpty()) {
            String difficultyText = String.join("、", difficulty);
            if (difficultyText.contains("零基础") && containsAnyActionKeyword(actionName, "拉伸", "放松", "呼吸", "按摩")) {
                score += 1.2D;
            }
            if ((difficultyText.contains("有难度") || difficultyText.contains("进阶"))
                    && containsAnyActionKeyword(actionName, "动态", "旋转", "绕环", "力量", "活动")) {
                score += 1.2D;
            }
        }

        return score;
    }

    private boolean matchesAnyPreference(String actionName, List<String> preferences) {
        if (preferences == null || preferences.isEmpty()) {
            return false;
        }
        String normalizedAction = normalizeForCompare(actionName);
        for (String preference : preferences) {
            String normalizedPreference = normalizeForCompare(preference);
            if (normalizedPreference.isBlank()) {
                continue;
            }
            if (normalizedAction.contains(normalizedPreference) || normalizedPreference.contains(normalizedAction)) {
                return true;
            }
            if (containsMappedKeyword(normalizedAction, preference)) {
                return true;
            }
        }
        return false;
    }

    private boolean containsMappedKeyword(String normalizedAction, String preference) {
        return switch (preference) {
            case "颈部" -> containsAnyNormalized(normalizedAction, "颈", "脖", "下巴");
            case "肩部" -> containsAnyNormalized(normalizedAction, "肩", "耸肩");
            case "腰部" -> containsAnyNormalized(normalizedAction, "腰");
            case "背部" -> containsAnyNormalized(normalizedAction, "背", "脊");
            case "腿部" -> containsAnyNormalized(normalizedAction, "腿", "膝", "踝", "臀");
            case "手腕" -> containsAnyNormalized(normalizedAction, "腕", "手", "指");
            case "静态拉伸" -> containsAnyNormalized(normalizedAction, "拉伸", "伸展");
            case "动态拉伸" -> containsAnyNormalized(normalizedAction, "摆", "动态");
            case "关节活动" -> containsAnyNormalized(normalizedAction, "绕环", "旋转", "活动");
            case "按摩放松" -> containsAnyNormalized(normalizedAction, "按摩", "按压", "放松");
            case "体态矫正" -> containsAnyNormalized(normalizedAction, "体态", "收下巴", "矫正");
            case "深呼吸" -> containsAnyNormalized(normalizedAction, "呼吸");
            default -> false;
        };
    }

    private boolean containsAnyActionKeyword(String actionName, String... keywords) {
        return containsAnyNormalized(normalizeForCompare(actionName), keywords);
    }

    private boolean containsAnyNormalized(String source, String... keywords) {
        for (String keyword : keywords) {
            if (source.contains(normalizeForCompare(keyword))) {
                return true;
            }
        }
        return false;
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

    private Double doubleValue(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Number number) {
            return number.doubleValue();
        }
        try {
            return Double.parseDouble(value.toString());
        } catch (NumberFormatException e) {
            return null;
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

        List<Integer> preferredDurations = extractPreferredDurationSeconds(userInfo);
        if (!preferredDurations.isEmpty()) {
            duration = preferredDurations.get(0);
        }

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

        if (userInfo.get("preferred_difficulty") instanceof List<?> list && !list.isEmpty()) {
            String preferredDifficulty = String.valueOf(list.get(0));
            if (preferredDifficulty.contains("零基础") || preferredDifficulty.contains("入门")) {
                return "入门";
            }
            if (preferredDifficulty.contains("有难度") || preferredDifficulty.contains("进阶")) {
                return "进阶";
            }
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

    private List<Integer> extractPreferredDurationSeconds(Map<String, Object> userInfo) {
        if (!(userInfo.get("preferred_durations") instanceof List<?> list)) {
            return Collections.emptyList();
        }
        List<Integer> result = new ArrayList<>();
        for (Object item : list) {
            java.util.regex.Matcher matcher = java.util.regex.Pattern.compile("(\\d+)").matcher(String.valueOf(item));
            if (matcher.find()) {
                result.add(Integer.parseInt(matcher.group(1)) * 60);
            }
        }
        return result;
    }

    private List<String> extractStringList(Object value) {
        if (!(value instanceof List<?> list)) {
            return Collections.emptyList();
        }
        return list.stream()
                .map(String::valueOf)
                .filter(item -> !item.isBlank())
                .toList();
    }
}
