package com.kuibuqianli.dto;

import lombok.Data;

/**
 * 用户数据传输对象
 */
@Data
public class UserDTO {
    private Long id;
    private String username;
    private String email;
    private String phone;
    private Boolean isActive;
}
// 用户数据传输对象