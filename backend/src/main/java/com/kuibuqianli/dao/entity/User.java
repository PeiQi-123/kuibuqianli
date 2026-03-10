package com.kuibuqianli.dao.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 用户实体类
 */
@Data
@TableName("user")
public class User {
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    @TableField("username")
    private String username;

    @TableField("password")
    private String password;

    @TableField("email")
    private String email;

    @TableField("phone")
    private String phone;

    @TableField("height")
    private BigDecimal height;

    @TableField("weight")
    private BigDecimal weight;

    @TableField("bmi")
    private BigDecimal bmi;

    @TableField("bmi_type")
    private String bmiType;

    @TableField("age")
    private Integer age;

    @TableField("gender")
    private String gender;

    @TableField("remind_enabled")
    private Boolean remindEnabled;

    @TableField("remind_interval")
    private Integer remindInterval;

    @TableField("remind_max_times")
    private Integer remindMaxTimes;

    @TableField("remind_avoid_time")
    private String remindAvoidTime;

    @TableField("created_at")
    private LocalDateTime createdAt;

    @TableField("updated_at")
    private LocalDateTime updatedAt;

    @TableField("is_active")
    private Boolean isActive;
}
// 用户实体类