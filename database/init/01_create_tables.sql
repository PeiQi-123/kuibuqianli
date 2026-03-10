-- 创建数据库表结构脚本
-- 跬步千里 - 微运动健康管理系统

-- 用户表
CREATE TABLE IF NOT EXISTS `user` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '用户ID',
    `username` VARCHAR(50) NOT NULL COMMENT '用户名',
    `password` VARCHAR(255) NOT NULL COMMENT '密码（加密）',
    `email` VARCHAR(100) DEFAULT NULL COMMENT '邮箱',
    `phone` VARCHAR(20) DEFAULT NULL COMMENT '手机号',
    `height` DECIMAL(5,2) DEFAULT NULL COMMENT '身高（厘米）',
    `weight` DECIMAL(5,2) DEFAULT NULL COMMENT '体重（公斤）',
    `bmi` DECIMAL(4,2) DEFAULT NULL COMMENT 'BMI指数',
    `bmi_type` VARCHAR(10) DEFAULT NULL COMMENT 'BMI类型（正常/偏胖/肥胖/偏瘦）',
    `age` INT DEFAULT NULL COMMENT '年龄',
    `gender` VARCHAR(10) DEFAULT NULL COMMENT '性别（男/女）',
    `remind_enabled` TINYINT(1) DEFAULT 1 COMMENT '是否启用提醒（0-否，1-是）',
    `remind_interval`  INT DEFAULT NULL COMMENT '提醒间隔（分钟）',
    `remind_max_times` INT DEFAULT NULL COMMENT '最大提醒次数',
    `remind_avoid_time` JSON DEFAULT NULL COMMENT '避免提醒时间段（JSON格式）',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `is_active` TINYINT(1) DEFAULT 1 COMMENT '是否激活',
    `deleted` TINYINT(1) DEFAULT 0 COMMENT '是否删除（逻辑删除）',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_username` (`username`),
    UNIQUE KEY `uk_email` (`email`),
    KEY `idx_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 用户偏好表
CREATE TABLE IF NOT EXISTS `user_preference` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '偏好ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `preference_key` VARCHAR(50) NOT NULL COMMENT '偏好键',
    `preference_value` TEXT COMMENT '偏好值',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_preference_key` (`preference_key`),
    CONSTRAINT `fk_user_preference_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
    CONSTRAINT `chk_preference_key` CHECK (
        `preference_key` IN (
            'body_part',      -- 身体部位
            'difficulty',     -- 难度
            'sport_type',     -- 运动类型
            'scene',          -- 场景
            'duration',       -- 时长
            'bmi_type',       -- BMI类型
            'special_case',   -- 特殊情况
            'silent',         -- 静音
            'pace',           -- 节奏
            'other_features'  -- 其他特征
        )
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户偏好表';

-- 运动记录表
CREATE TABLE IF NOT EXISTS `exercise_record` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '记录ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `motion_id` VARCHAR(50) DEFAULT NULL COMMENT '运动ID',
    `motion_name` VARCHAR(100) DEFAULT NULL COMMENT '运动名称',
    `duration` INT DEFAULT NULL COMMENT '运动时长（秒）',
    `completed` TINYINT(1) DEFAULT 0 COMMENT '是否完成',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_created_at` (`created_at`),
    CONSTRAINT `fk_exercise_record_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='运动记录表';

-- 设备数据表
CREATE TABLE IF NOT EXISTS `device_data` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '数据ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `device_id` VARCHAR(50) DEFAULT NULL COMMENT '设备ID',
    `data_type` VARCHAR(50) DEFAULT NULL COMMENT '数据类型',
    `data_value` TEXT COMMENT '数据值（JSON格式）',
    `recorded_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间',
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_device_id` (`device_id`),
    KEY `idx_recorded_at` (`recorded_at`),
    CONSTRAINT `fk_device_data_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='设备数据表';

-- 提醒日志表
CREATE TABLE IF NOT EXISTS `remind_log` (
    `log_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '日志ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `actual_time` DATETIME NOT NULL COMMENT '实际提醒时间',
    `in_avoid_period` TINYINT(1) DEFAULT 0 COMMENT '是否在免打扰时间段（0-否，1-是）',
    `status` VARCHAR(10) NOT NULL COMMENT '状态（success-成功，failed-失败，skipped-跳过）',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`log_id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_actual_time` (`actual_time`),
    KEY `idx_status` (`status`),
    CONSTRAINT `fk_remind_log_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
    CONSTRAINT `chk_status` CHECK (`status` IN ('success', 'failed', 'skipped'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='提醒日志表';
