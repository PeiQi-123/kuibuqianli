package com.kuibuqianli.controller;

import com.kuibuqianli.common.Result;
import com.kuibuqianli.dto.ReminderLogCreateDTO;
import com.kuibuqianli.dto.ReminderStatusDTO;
import com.kuibuqianli.service.ReminderService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "久坐提醒")
@RestController
@RequestMapping("/reminder")
public class ReminderController {

    @Autowired
    private ReminderService reminderService;

    @Operation(summary = "获取当前提醒状态")
    @GetMapping("/status")
    public Result<ReminderStatusDTO> getReminderStatus(@RequestParam Long userId) {
        return Result.success(reminderService.getReminderStatus(userId));
    }

    @Operation(summary = "记录提醒日志")
    @PostMapping("/log")
    public Result<String> createReminderLog(@RequestParam Long userId, @RequestBody ReminderLogCreateDTO dto) {
        boolean success = reminderService.createReminderLog(userId, dto);
        return success ? Result.success("提醒日志记录成功") : Result.error("提醒日志记录失败");
    }
}
