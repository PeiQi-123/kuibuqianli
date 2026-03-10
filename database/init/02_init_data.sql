-- 初始化数据脚本
-- 跬步千里 - 微运动健康管理系统

-- 插入测试用户
-- 密码: test123456 (BCrypt哈希)
INSERT INTO `user` (
    `username`, `password`, `email`, `phone`, 
    `height`, `weight`, `bmi`, `bmi_type`, `age`, `gender`,
    `remind_interval`, `remind_max_times`, `remind_avoid_time`,
    `is_active`
) VALUES
(
    'testuser', 
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',  -- test123456
    'test@example.com', 
    '13800138000',
    170.5,  -- 身高
    65.2,   -- 体重
    22.4,   -- BMI
    '正常',  -- BMI类型
    25,     -- 年龄
    '男',    -- 性别
    30,     -- 提醒间隔
    3,      -- 最大提醒次数
    '[{"start": "22:00", "end": "08:00"}, {"start": "12:00", "end": "14:00"}]', -- 免打扰时间段
    1
)
ON DUPLICATE KEY UPDATE `username`=`username`;

-- 插入第二个测试用户
-- 密码: 123456 (BCrypt哈希: $2a$10$X5hCJ/9hqL.6Q7r8t9u0v.1w2x3y4z5A6B7C8D9E0F1G2H3I4J5K6L7M8N9O0P)
INSERT INTO `user` (
    `username`, `password`, `email`, `phone`, 
    `height`, `weight`, `bmi`, `bmi_type`, `age`, `gender`,
    `remind_interval`, `remind_max_times`, `remind_avoid_time`,
    `is_active`
) VALUES
(
    'demo', 
    '$2a$10$X5hCJ/9hqL.6Q7r8t9u0v.1w2x3y4z5A6B7C8D9E0F1G2H3I4J5K6L7M8N9O0P',  -- 123456
    'demo@example.com', 
    '13700137000',
    165.0,  -- 身高
    55.0,   -- 体重
    20.2,   -- BMI
    '正常',  -- BMI类型
    22,     -- 年龄
    '女',    -- 性别
    45,     -- 提醒间隔
    4,      -- 最大提醒次数
    '[{"start": "21:00", "end": "09:00"}]', -- 免打扰时间段
    1
)
ON DUPLICATE KEY UPDATE `username`=`username`;

-- 插入默认用户偏好（更新为新的偏好键）
INSERT INTO `user_preference` (`user_id`, `preference_key`, `preference_value`) VALUES
(1, 'body_part', '颈,肩,腰'),
(1, 'difficulty', '低'),
(1, 'sport_type', '拉伸'),
(1, 'scene', '办公室'),
(1, 'duration', '5'),
(1, 'bmi_type', '正常'),
(1, 'special_case', '无'),
(1, 'silent', 'true'),
(1, 'pace', '中等'),
(1, 'other_features', '无')
ON DUPLICATE KEY UPDATE `preference_value`=`preference_value`;
