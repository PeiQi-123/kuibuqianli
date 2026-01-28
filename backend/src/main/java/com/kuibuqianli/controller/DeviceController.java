package com.kuibuqianli.controller;

import com.kuibuqianli.common.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * 设备控制器：处理手环相关接口
 */
@Tag(name = "设备管理")
@RestController
@RequestMapping("/device")
public class DeviceController {

    @Operation(summary = "接收设备数据")
    @PostMapping("/data")
    public Result<String> receiveDeviceData(@RequestBody Map<String, Object> deviceData) {
        // 模拟接收手环数据，实际应用中需要处理陀螺仪、距离等信息
        System.out.println("Received device data: " + deviceData);
        return Result.success("设备数据接收成功");
    }

    @Operation(summary = "获取设备状态")
    @GetMapping("/status/{deviceId}")
    public Result<Map<String, Object>> getDeviceStatus(@PathVariable String deviceId) {
        // 返回设备状态信息 - 使用Java 8兼容的方式创建Map
        Map<String, Object> status = new HashMap<>();
        status.put("deviceId", deviceId);
        status.put("connected", true);
        status.put("batteryLevel", 85);
        status.put("lastUpdate", System.currentTimeMillis());

        return Result.success(status);
    }
}
