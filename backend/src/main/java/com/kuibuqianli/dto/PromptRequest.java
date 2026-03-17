package com.kuibuqianli.dto;

import lombok.Data;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.Map;

/**
 * 微运动提示词生成请求DTO
 */
@Data
public class PromptRequest {

    /**
     * 用户选择的部位文字信息
     * 例如：颈部、腰部、肩部等
     */
    @JsonProperty("body_part")
    private String bodyPart;

    /**
     * 用户姿态信息
     * 例如：坐姿、站姿、角度等
     */
    @JsonProperty("posture_info")
    private String postureInfo;

    /**
     * 用户表信息
     * 包含年龄、身高、体重、BMI等
     */
    @JsonProperty("user_info")
    private Map<String, Object> userInfo;
}