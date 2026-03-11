package com.kuibuqianli.dto;

import lombok.Data;
import lombok.Builder;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * 微运动提示词生成响应DTO
 */
@Data
@Builder
public class PromptResponse {

    /**
     * 生成的微运动提示词文本
     */
    @JsonProperty("prompt_text")
    private String promptText;

    /**
     * 建议运动时长（秒）
     */
    @JsonProperty("suggested_duration")
    private Integer suggestedDuration;

    /**
     * 难度级别（入门/进阶/专家）
     */
    @JsonProperty("difficulty_level")
    private String difficultyLevel;

    /**
     * API使用情况
     */
    @JsonProperty("api_usage")
    private ApiUsage apiUsage;

    /**
     * 响应状态
     */
    @JsonProperty("status")
    private String status;

    /**
     * 错误信息（如果有）
     */
    @JsonProperty("error_message")
    private String errorMessage;

    /**
     * API使用情况内部类
     */
    @Data
    @Builder
    public static class ApiUsage {

        /**
         * 提示token数
         */
        @JsonProperty("prompt_tokens")
        private int promptTokens;

        /**
         * 完成token数
         */
        @JsonProperty("completion_tokens")
        private int completionTokens;

        /**
         * 总token数
         */
        @JsonProperty("total_tokens")
        private int totalTokens;
    }

    /**
     * 创建成功响应
     */
    public static PromptResponse success(String promptText, Integer duration,
                                         String difficulty, ApiUsage usage) {
        return PromptResponse.builder()
                .promptText(promptText)
                .suggestedDuration(duration)
                .difficultyLevel(difficulty)
                .apiUsage(usage)
                .status("success")
                .build();
    }

    /**
     * 创建失败响应
     */
    public static PromptResponse error(String errorMessage) {
        return PromptResponse.builder()
                .status("error")
                .errorMessage(errorMessage)
                .build();
    }
}