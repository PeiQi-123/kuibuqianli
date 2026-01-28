package com.kuibuqianli.dto;

import lombok.Data;

// 将 javax.validation.constraints 替换为 jakarta.validation.constraints
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Pattern;

/**
 * 注册请求DTO
 */
@Data
public class RegisterDTO {
    @NotBlank(message = "用户名不能为空")
    @Pattern(regexp = "^[a-zA-Z0-9_]{3,20}$", message = "用户名只能包含字母、数字和下划线，长度为3-20位")
    private String username;

    @NotBlank(message = "密码不能为空")
    @Pattern(regexp = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d@$!%*#?&]{6,}$", message = "密码至少包含一个字母和一个数字，长度至少6位")
    private String password;

    @NotBlank(message = "邮箱不能为空")
    @Email(message = "邮箱格式不正确")
    private String email;

    private String phone;
}
// 注册请求DTO