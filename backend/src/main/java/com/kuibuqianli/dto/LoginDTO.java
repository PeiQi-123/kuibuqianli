package com.kuibuqianli.dto;
import lombok.Data;
import jakarta.validation.constraints.NotBlank;



/**
 * 登录请求DTO
 */
@Data
public class LoginDTO {
    @NotBlank(message = "用户名不能为空")
    private String username;

    @NotBlank(message = "密码不能为空")
    private String password;
}
// 登录请求DTO