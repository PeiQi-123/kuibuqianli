-- 创建数据库表结构脚本
-- 跬步千里 - 微运动健康管理系统

-- 用户表
CREATE TABLE IF NOT EXISTS `user` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '用户ID',
    `username` VARCHAR(50) NOT NULL COMMENT '用户名',
    `password` VARCHAR(255) NOT NULL COMMENT '密码（加密）',
    `email` VARCHAR(100) DEFAULT NULL COMMENT '邮箱',
    `phone` VARCHAR(20) DEFAULT NULL COMMENT '手机号',
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
    CONSTRAINT `fk_user_preference_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
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
