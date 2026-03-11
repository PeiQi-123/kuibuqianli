package com.kuibuqianli.dto;

import lombok.Data;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

/**
 * DeepSeek API响应DTO
 */
@Data
public class DeepSeekResponse {

    /**
     * 响应ID
     */
    private String id;

    /**
     * 对象类型
     */
    private String object;

    /**
     * 创建时间戳
     */
    private long created;

    /**
     * 使用的模型
     */
    private String model;

    /**
     * 选择列表
     */
    private List<Choice> choices;

    /**
     * token使用情况
     */
    private Usage usage;

    /**
     * 选择内部类
     */
    @Data
    public static class Choice {

        /**
         * 索引
         */
        private int index;

        /**
         * 消息
         */
        private Message message;

        /**
         * 结束原因
         */
        @JsonProperty("finish_reason")
        private String finishReason;

        /**
         * 消息内部类
         */
        @Data
        public static class Message {

            /**
             * 角色
             */
            private String role;

            /**
             * 内容
             */
            private String content;
        }
    }

    /**
     * token使用情况内部类
     */
    @Data
    public static class Usage {

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
}