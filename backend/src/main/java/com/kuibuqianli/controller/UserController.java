package com.kuibuqianli.controller;

import com.kuibuqianli.common.Result;
import com.kuibuqianli.dto.LoginDTO;
import com.kuibuqianli.dto.RegisterDTO;
import com.kuibuqianli.dto.HealthDataDTO;
import com.kuibuqianli.dto.UserDTO;
import com.kuibuqianli.dto.UserPreferenceDTO;
import com.kuibuqianli.dto.UserPreferencesUpdateDTO;
import com.kuibuqianli.service.HealthDataService;
import com.kuibuqianli.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;
import com.kuibuqianli.dto.LoginResponseDTO;
import com.kuibuqianli.common.exception.BusinessException;

import java.util.List;
import java.util.Map;

/**
 * 用户控制器：处理注册、登录、用户信息
 */
@Tag(name = "用户管理")
@RestController
@RequestMapping("/user")
public class UserController {

    @Autowired
    private UserService userService;

    @Autowired
    private HealthDataService healthDataService;

    @Operation(summary = "用户注册")
    @PostMapping("/register")
    public Result<String> register(@Valid @RequestBody RegisterDTO registerDTO) {
        userService.register(registerDTO);
        return Result.success("注册成功");
    }

    @Operation(summary = "用户登录")
    @PostMapping("/login")
    public Result<LoginResponseDTO> login(@Valid @RequestBody LoginDTO loginDTO) {
        try {
            // 使用UserService处理登录逻辑
            LoginResponseDTO response = userService.loginWithUser(loginDTO);
            return Result.success(response);
        } catch (BusinessException e) {
            // 异常会被全局异常处理器捕获，这里直接抛出
            throw e;
        }
    }



    @Operation(summary = "获取用户信息")
    @GetMapping("/info")
    public Result<UserDTO> getUserInfo(@RequestParam Long userId) {
        UserDTO userDTO = userService.getUserInfo(userId);
        return Result.success(userDTO);
    }

    @Operation(summary = "更新用户信息")
    @PostMapping("/update")
    public Result<String> updateUserInfo(@RequestParam Long userId, @RequestBody UserDTO userDTO) {
        boolean success = userService.updateUserInfo(userId, userDTO);
        if (success) {
            return Result.success("用户信息更新成功");
        } else {
            return Result.error("用户信息更新失败");
        }
    }

    @Operation(summary = "获取用户偏好")
    @GetMapping("/preferences")
    public Result<List<UserPreferenceDTO>> getUserPreferences(@RequestParam Long userId) {
        List<UserPreferenceDTO> preferences = userService.getUserPreferences(userId);
        return Result.success(preferences);
    }

    @Operation(summary = "保存用户偏好")
    @PostMapping("/preferences")
    public Result<String> saveUserPreferences(@RequestParam Long userId, 
                                             @RequestBody UserPreferencesUpdateDTO preferencesDTO) {
        boolean success = userService.saveUserPreferences(userId, preferencesDTO);
        if (success) {
            return Result.success("用户偏好保存成功");
        } else {
            return Result.error("用户偏好保存失败");
        }
    }

    @Operation(summary = "获取用户健康数据")
    @GetMapping("/health-data")
    public Result<HealthDataDTO> getUserHealthData(@RequestParam Long userId) {
        return Result.success(healthDataService.getUserHealthData(userId));
    }

    @Operation(summary = "更新用户头像")
    @PostMapping("/avatar")
    public Result<String> updateAvatar(@RequestParam Long userId, @RequestBody Map<String, String> body) {
        String avatarUrl = body.get("avatarUrl");
        if (avatarUrl == null || avatarUrl.isEmpty()) {
            return Result.error("头像URL不能为空");
        }
        boolean success = userService.updateAvatar(userId, avatarUrl);
        if (success) {
            return Result.success(avatarUrl);
        } else {
            return Result.error("头像更新失败");
        }
    }
}
// 用户控制器：处理注册、登录、用户信息
