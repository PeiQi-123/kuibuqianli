package com.kuibuqianli.dao.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户偏好实体类
 */
@Data
@TableName("user_preference")
public class UserPreference {
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    @TableField("user_id")
    private Long userId;

    @TableField("activity_type")
    private String activityType; // 活动类型：久坐、长时间使用电脑等

    @TableField("preference_style")
    private String preferenceStyle; // 偏好风格：常规、有趣等

    @TableField("exercise_duration")
    private Integer exerciseDuration; // 运动时长（秒）

    @TableField("difficulty_level")
    private String difficultyLevel; // 难度等级

    @TableField("rating")
    private Double rating; // 用户评分

    @TableField("created_at")
    private LocalDateTime createdAt;

    @TableField("updated_at")
    private LocalDateTime updatedAt;
}
// 用户偏好实体类