-- 初始化数据脚本
-- 跬步千里 - 微运动健康管理系统

-- 插入测试用户（密码: test123456，已加密，实际使用时需要修改）
-- 注意：实际密码应该使用 BCrypt 加密，这里只是示例
INSERT INTO `user` (`username`, `password`, `email`, `phone`, `is_active`) VALUES
('testuser', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'test@example.com', '13800138000', 1)
ON DUPLICATE KEY UPDATE `username`=`username`;

-- 插入默认用户偏好
INSERT INTO `user_preference` (`user_id`, `preference_key`, `preference_value`) VALUES
(1, 'exercise_intensity', 'low'),
(1, 'exercise_duration', '5'),
(1, 'reminder_enabled', 'true')
ON DUPLICATE KEY UPDATE `preference_value`=`preference_value`;
