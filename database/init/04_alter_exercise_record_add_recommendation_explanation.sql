DROP PROCEDURE IF EXISTS `add_exercise_record_recommendation_columns`;

DELIMITER $$

CREATE PROCEDURE `add_exercise_record_recommendation_columns`()
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'exercise_record'
          AND COLUMN_NAME = 'recommendation_summary'
    ) THEN
        ALTER TABLE `exercise_record`
            ADD COLUMN `recommendation_summary` VARCHAR(255) DEFAULT NULL COMMENT '本次推荐的偏好解释摘要' AFTER `completed`;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'exercise_record'
          AND COLUMN_NAME = 'recommendation_matched_items'
    ) THEN
        ALTER TABLE `exercise_record`
            ADD COLUMN `recommendation_matched_items` JSON DEFAULT NULL COMMENT '本次推荐命中的偏好项' AFTER `recommendation_summary`;
    END IF;
END $$

DELIMITER ;

CALL `add_exercise_record_recommendation_columns`();

DROP PROCEDURE IF EXISTS `add_exercise_record_recommendation_columns`;
