package com.kuibuqianli.dto;

import lombok.Data;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * 用户数据传输对象
 */
@Data
public class UserDTO {
    private Long id;
    private String username;
    private String email;
    private String phone;
    private BigDecimal height;
    private BigDecimal weight;
    private BigDecimal bmi;
    private String bmiType;
    private Integer age;
    private String gender;
    private Boolean remindEnabled;
    private Integer remindInterval;
    private Integer remindMaxTimes;
    private List<Map<String, String>> remindAvoidTime;
    private Boolean isActive;
    private String password;
    private String avatarUrl;
}
// 用户数据传输对象