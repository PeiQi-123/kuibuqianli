-- Align existing user table with backend User entity.

SET @sql = IF(
    EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user' AND COLUMN_NAME = 'height'
    ),
    'SELECT 1',
    'ALTER TABLE `user` ADD COLUMN `height` DECIMAL(5,2) DEFAULT NULL COMMENT ''Height in centimeters'' AFTER `phone`'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
    EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user' AND COLUMN_NAME = 'weight'
    ),
    'SELECT 1',
    'ALTER TABLE `user` ADD COLUMN `weight` DECIMAL(5,2) DEFAULT NULL COMMENT ''Weight in kilograms'' AFTER `height`'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
    EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user' AND COLUMN_NAME = 'bmi'
    ),
    'SELECT 1',
    'ALTER TABLE `user` ADD COLUMN `bmi` DECIMAL(4,2) DEFAULT NULL COMMENT ''BMI value'' AFTER `weight`'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
    EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user' AND COLUMN_NAME = 'bmi_type'
    ),
    'SELECT 1',
    'ALTER TABLE `user` ADD COLUMN `bmi_type` VARCHAR(10) DEFAULT NULL COMMENT ''BMI category'' AFTER `bmi`'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
    EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user' AND COLUMN_NAME = 'age'
    ),
    'SELECT 1',
    'ALTER TABLE `user` ADD COLUMN `age` INT DEFAULT NULL COMMENT ''Age'' AFTER `bmi_type`'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
    EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user' AND COLUMN_NAME = 'gender'
    ),
    'SELECT 1',
    'ALTER TABLE `user` ADD COLUMN `gender` VARCHAR(10) DEFAULT NULL COMMENT ''Gender'' AFTER `age`'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
    EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user' AND COLUMN_NAME = 'remind_enabled'
    ),
    'SELECT 1',
    'ALTER TABLE `user` ADD COLUMN `remind_enabled` TINYINT(1) DEFAULT 1 COMMENT ''Reminder enabled flag'' AFTER `gender`'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
    EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user' AND COLUMN_NAME = 'remind_interval'
    ),
    'SELECT 1',
    'ALTER TABLE `user` ADD COLUMN `remind_interval` INT DEFAULT NULL COMMENT ''Reminder interval in minutes'' AFTER `remind_enabled`'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
    EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user' AND COLUMN_NAME = 'remind_max_times'
    ),
    'SELECT 1',
    'ALTER TABLE `user` ADD COLUMN `remind_max_times` INT DEFAULT NULL COMMENT ''Maximum reminder count'' AFTER `remind_interval`'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
    EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user' AND COLUMN_NAME = 'remind_avoid_time'
    ),
    'SELECT 1',
    'ALTER TABLE `user` ADD COLUMN `remind_avoid_time` JSON DEFAULT NULL COMMENT ''Reminder quiet periods as JSON'' AFTER `remind_max_times`'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
