package com.kuibuqianli.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import java.util.List;

/**
 * DeepSeek API请求DTO
 */
@Data
public class DeepSeekRequest {

    /**
     * 模型名称
     */
    private String model;

    /**
     * 消息列表
     */
    private List<Message> messages;

    /**
     * 是否流式输出
     */
    private boolean stream = false;

    /**
     * 温度参数（0-2）
     */
    private Double temperature;

    /**
     * 最大输出token数
     */
    @JsonProperty("max_tokens")
    private Integer maxTokens;

    /**
     * 消息内部类
     */
    @Data
    public static class Message {

        /**
         * 角色：system, user, assistant
         */
        private String role;

        /**
         * 消息内容
         */
        private String content;

        public Message() {
        }

        public Message(String role, String content) {
            this.role = role;
            this.content = content;
        }
    }
}