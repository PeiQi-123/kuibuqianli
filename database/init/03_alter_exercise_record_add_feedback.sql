ALTER TABLE `exercise_record`
    ADD COLUMN IF NOT EXISTS `feedback_tag` VARCHAR(20) DEFAULT NULL COMMENT '反馈标签（too_easy, fit, too_hard, dislike）' AFTER `completed`,
    ADD COLUMN IF NOT EXISTS `feedback_score` INT DEFAULT NULL COMMENT '反馈分值（1-4）' AFTER `feedback_tag`,
    ADD COLUMN IF NOT EXISTS `feedback_at` DATETIME DEFAULT NULL COMMENT '反馈时间' AFTER `feedback_score`;
