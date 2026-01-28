package com.kuibuqianli.controller;

import com.kuibuqianli.common.Result;
import com.kuibuqianli.dto.LoginDTO;
import com.kuibuqianli.dto.RegisterDTO;
import com.kuibuqianli.dto.UserDTO;
import com.kuibuqianli.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;
import com.kuibuqianli.dto.LoginResponseDTO;
import com.kuibuqianli.common.exception.BusinessException;

/**
 * 用户控制器：处理注册、登录、用户信息
 */
@Tag(name = "用户管理")
@RestController
@RequestMapping("/user")
public class UserController {

    @Autowired
    private UserService userService;

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
}
// 用户控制器：处理注册、登录、用户信息
