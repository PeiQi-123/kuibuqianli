package com.kuibuqianli.dao.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * User Preference Entity
 * Corresponds to database table: user_preference
 */
@Data
@TableName("user_preference")
public class UserPreference {
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    @TableField("user_id")
    private Long userId;

    @TableField("preference_key")
    private String preferenceKey;

    @TableField("preference_value")
    private String preferenceValue; // JSON format string, e.g.: ["shoulder", "back"]

    @TableField("created_at")
    private LocalDateTime createdAt;

    @TableField("updated_at")
    private LocalDateTime updatedAt;
}