package com.kuibuqianli.controller;

import com.kuibuqianli.common.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 健康检查接口
 */
@Tag(name = "健康检查")
@RestController
@RequestMapping("/health")
public class HealthController {

    @Operation(summary = "服务健康检查")
    @GetMapping
    public Result<String> healthCheck() {
        return Result.success("服务运行正常");
    }
}
// 健康检查接口
