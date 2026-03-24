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
    `preference_value` JSON DEFAULT NULL COMMENT '偏好值',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_preference_key` (`preference_key`),
    CONSTRAINT `fk_user_preference_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
    -- 约束名加表前缀：up_ = user_preference
    CONSTRAINT `chk_up_preference_key` CHECK (
        `preference_key` IN (
            'body_part',
            'difficulty',
            'sport_type',
            'scene',
            'duration',
            'special_case',
            'pace'
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
    `recommendation_summary` VARCHAR(255) DEFAULT NULL COMMENT '本次推荐的偏好解释摘要',
    `recommendation_matched_items` JSON DEFAULT NULL COMMENT '本次推荐命中的偏好项',
    `feedback_tag` VARCHAR(20) DEFAULT NULL COMMENT '反馈标签（too_easy, fit, too_hard, dislike）',
    `feedback_score` INT DEFAULT NULL COMMENT '反馈分值（1-4）',
    `feedback_at` DATETIME DEFAULT NULL COMMENT '反馈时间',
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
    -- 约束名加表前缀：rl_ = remind_log
    CONSTRAINT `chk_rl_status` CHECK (`status` IN ('success', 'failed', 'skipped'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='提醒日志表';

-- 视频信息表
CREATE TABLE IF NOT EXISTS `video` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '视频ID',
    `title` VARCHAR(200) NOT NULL COMMENT '视频标题',
    `description` TEXT COMMENT '视频描述',
    `file_path` VARCHAR(500) COMMENT '文件存储路径',
    `file_url` VARCHAR(500) COMMENT '视频访问URL',
    `duration` INT COMMENT '视频时长（秒）',
    `file_size` BIGINT COMMENT '文件大小（字节）',
    `format` VARCHAR(20) COMMENT '视频格式（mp4, avi等）',
    `resolution` VARCHAR(20) COMMENT '分辨率（720p, 1080p等）',
    `thumbnail_path` VARCHAR(500) COMMENT '缩略图路径',
    `status` VARCHAR(20) DEFAULT 'active' COMMENT '状态（active-活跃, deleted-已删除, hidden-隐藏）',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_status` (`status`),
    KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='视频信息表';

-- 视频属性表
CREATE TABLE IF NOT EXISTS `video_attribute` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '属性ID',
    `video_id` BIGINT NOT NULL COMMENT '视频ID',
    `attribute_type` VARCHAR(50) NOT NULL COMMENT '属性类型',
    `attribute_value` VARCHAR(100) NOT NULL COMMENT '属性值',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_video_attribute` (`video_id`, `attribute_type`, `attribute_value`),
    KEY `idx_video_id` (`video_id`),
    KEY `idx_attribute_type` (`attribute_type`),
    KEY `idx_attribute_value` (`attribute_value`),
    CONSTRAINT `fk_video_attribute_video` FOREIGN KEY (`video_id`) REFERENCES `video` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='视频属性表';

-- 视频属性类型约束（约束名加表前缀：va_ = video_attribute，避免重复）
ALTER TABLE `video_attribute`
ADD CONSTRAINT `chk_va_attribute_type` CHECK (
    `attribute_type` IN (
        'body_part',
        'difficulty',
        'pace',
        'sport_type',
        'scene',
        'contraindication',
        'suitable_bmi',
        'duration_category'
    )
);

-- 运动视频关联表
CREATE TABLE IF NOT EXISTS `exercise_video` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '关联ID',
    `exercise_record_id` BIGINT COMMENT '运动记录ID',
    `video_id` BIGINT NOT NULL COMMENT '视频ID',
    `video_type` VARCHAR(20) NOT NULL COMMENT '视频类型（recommendation-推荐视频, user_record-用户记录, tutorial-教程）',
    `sequence` INT DEFAULT 1 COMMENT '播放顺序',
    `is_primary` TINYINT(1) DEFAULT 0 COMMENT '是否主视频（0-否，1-是）',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    KEY `idx_exercise_record_id` (`exercise_record_id`),
    KEY `idx_video_id` (`video_id`),
    KEY `idx_video_type` (`video_type`),
    CONSTRAINT `fk_exercise_video_exercise_record` FOREIGN KEY (`exercise_record_id`) REFERENCES `exercise_record` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_exercise_video_video` FOREIGN KEY (`video_id`) REFERENCES `video` (`id`) ON DELETE CASCADE,
    -- 约束名加表前缀：ev_ = exercise_video
    CONSTRAINT `chk_ev_video_type` CHECK (`video_type` IN ('recommendation', 'user_record', 'tutorial'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='运动视频关联表';

-- 视频观看统计表
CREATE TABLE IF NOT EXISTS `video_statistics` (
    `video_id` BIGINT NOT NULL COMMENT '视频ID',
    `view_count` INT DEFAULT 0 COMMENT '观看次数',
    `completed_count` INT DEFAULT 0 COMMENT '完成次数',
    `avg_rating` DECIMAL(3,2) DEFAULT 0.00 COMMENT '平均评分',
    `last_viewed_at` DATETIME COMMENT '最后观看时间',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`video_id`),
    CONSTRAINT `fk_video_statistics_video` FOREIGN KEY (`video_id`) REFERENCES `video` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='视频观看统计表';
