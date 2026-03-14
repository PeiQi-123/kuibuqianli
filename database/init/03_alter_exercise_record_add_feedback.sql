DROP PROCEDURE IF EXISTS `add_exercise_record_feedback_columns`;

DELIMITER $$

CREATE PROCEDURE `add_exercise_record_feedback_columns`()
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'exercise_record'
          AND COLUMN_NAME = 'feedback_tag'
    ) THEN
        ALTER TABLE `exercise_record`
            ADD COLUMN `feedback_tag` VARCHAR(20) DEFAULT NULL COMMENT '反馈标签（too_easy, fit, too_hard, dislike）' AFTER `completed`;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'exercise_record'
          AND COLUMN_NAME = 'feedback_score'
    ) THEN
        ALTER TABLE `exercise_record`
            ADD COLUMN `feedback_score` INT DEFAULT NULL COMMENT '反馈分值（1-4）' AFTER `feedback_tag`;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'exercise_record'
          AND COLUMN_NAME = 'feedback_at'
    ) THEN
        ALTER TABLE `exercise_record`
            ADD COLUMN `feedback_at` DATETIME DEFAULT NULL COMMENT '反馈时间' AFTER `feedback_score`;
    END IF;
END $$

DELIMITER ;

CALL `add_exercise_record_feedback_columns`();

DROP PROCEDURE IF EXISTS `add_exercise_record_feedback_columns`;
