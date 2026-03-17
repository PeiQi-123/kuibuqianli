package com.kuibuqianli.controller;

import com.kuibuqianli.dto.PromptRequest;
import com.kuibuqianli.dto.PromptResponse;
import com.kuibuqianli.service.DeepSeekService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/micro-motion")
@CrossOrigin(origins = "http://localhost:3000", allowCredentials = "true")
public class MicroMotionController {

    @Autowired
    private DeepSeekService deepSeekService;

    /**
     * 生成微运动提示词
     * @param request 提示词请求（包含身体部位、姿态信息、用户信息）
     * @return 生成的微运动提示词
     */
    @PostMapping("/generate-prompt")
    public ResponseEntity<PromptResponse> generatePrompt(@Valid @RequestBody PromptRequest request) {
        log.info("========== 收到生成微运动提示词请求 ==========");
        log.info("身体部位: {}", request.getBodyPart());
        log.info("姿态信息: {}", request.getPostureInfo());
        log.info("用户信息: {}", request.getUserInfo());

        // 参数校验
        if (request.getBodyPart() == null || request.getBodyPart().trim().isEmpty()) {
            log.warn("身体部位不能为空");
            return ResponseEntity.badRequest()
                    .body(PromptResponse.error("身体部位不能为空"));
        }

        if (request.getPostureInfo() == null || request.getPostureInfo().trim().isEmpty()) {
            log.warn("姿态信息不能为空");
            return ResponseEntity.badRequest()
                    .body(PromptResponse.error("姿态信息不能为空"));
        }

        try {
            // 调用服务生成提示词
            PromptResponse response = deepSeekService.generateMicroMotionPrompt(request);

            // 检查响应状态
            if ("error".equals(response.getStatus())) {
                log.error("生成提示词失败: {}", response.getErrorMessage());
                return ResponseEntity.internalServerError().body(response);
            }

            log.info("提示词生成成功，时长: {}秒，难度: {}",
                    response.getSuggestedDuration(),
                    response.getDifficultyLevel());
            if (response.getApiUsage() != null) {
                log.info("Token使用 - 提示: {}, 完成: {}, 总计: {}",
                        response.getApiUsage().getPromptTokens(),
                        response.getApiUsage().getCompletionTokens(),
                        response.getApiUsage().getTotalTokens());
            }

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("生成提示词时发生异常", e);
            return ResponseEntity.internalServerError()
                    .body(PromptResponse.error("服务器内部错误: " + e.getMessage()));
        }
    }

    /**
     * 健康检查接口
     */
    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("微运动服务运行正常");
    }

    /**
     * 测试接口 - 返回固定提示词（用于前端开发测试）
     */
    @GetMapping("/test-prompt")
    public ResponseEntity<PromptResponse> testPrompt(
            @RequestParam(required = false, defaultValue = "颈部") String bodyPart,
            @RequestParam(required = false, defaultValue = "坐姿") String posture) {

        log.info("生成测试提示词 - bodyPart: {}, posture: {}", bodyPart, posture);

        // 生成一个固定的测试响应
        PromptResponse testResponse = PromptResponse.builder()
                .title(String.format("针对%s的微运动方案", bodyPart))
                .overview(String.format("适合%s不适和%s姿态的快速放松动作。", bodyPart, posture))
                .promptText(String.format("针对%s的微运动方案", bodyPart))
                .suggestedDuration(75)
                .difficultyLevel("入门")
                .actions(List.of(
                        PromptResponse.ActionItem.builder()
                                .name("颈部拉伸")
                                .seconds(15)
                                .instruction("缓慢将头向左倾斜，左耳靠近左肩，保持15秒。")
                                .warning("不要耸肩，保持呼吸。")
                                .build(),
                        PromptResponse.ActionItem.builder()
                                .name("颈部旋转")
                                .seconds(30)
                                .instruction("缓慢将头向左转看向左肩，再向右转。")
                                .warning("动作要缓慢，不要过度用力。")
                                .build(),
                        PromptResponse.ActionItem.builder()
                                .name("收下巴运动")
                                .seconds(30)
                                .instruction("保持头部水平，将下巴轻轻向后收。")
                                .warning("感觉颈部后侧有拉伸感即可。")
                                .build()
                ))
                .tip("每工作1小时做一组这些动作，有效缓解颈部疲劳。")
                .status("success")
                .build();

        return ResponseEntity.ok(testResponse);
    }

    /**
     * 带参数生成的接口 - 方便前端调试
     */
    @PostMapping("/generate-with-params")
    public ResponseEntity<PromptResponse> generateWithParams(
            @RequestParam String bodyPart,
            @RequestParam String postureInfo,
            @RequestBody(required = false) Object userInfo) {

        PromptRequest request = new PromptRequest();
        request.setBodyPart(bodyPart);
        request.setPostureInfo(postureInfo);

        return generatePrompt(request);
    }
}
