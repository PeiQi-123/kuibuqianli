DROP PROCEDURE IF EXISTS `create_recommendation_trace_table`;

DELIMITER $$

CREATE PROCEDURE `create_recommendation_trace_table`()
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'recommendation_trace'
    ) THEN
        CREATE TABLE `recommendation_trace` (
            `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '明细ID',
            `exercise_record_id` BIGINT NOT NULL COMMENT '运动记录ID',
            `action_name` VARCHAR(100) NOT NULL COMMENT '动作名称',
            `category` VARCHAR(50) DEFAULT NULL COMMENT '动作类别',
            `candidate_rank` INT DEFAULT NULL COMMENT '召回排序位置',
            `selected_rank` INT DEFAULT NULL COMMENT '最终入选排序位置',
            `selected` TINYINT(1) DEFAULT 0 COMMENT '是否最终入选',
            `recall_score` DECIMAL(8,4) DEFAULT NULL COMMENT '候选召回原始分',
            `normalized_recall_score` DECIMAL(8,4) DEFAULT NULL COMMENT '归一化召回分',
            `llm_rerank_score` DECIMAL(8,4) DEFAULT NULL COMMENT 'LLM重排分',
            `final_score` DECIMAL(8,4) DEFAULT NULL COMMENT '最终融合分',
            `recall_reasons` JSON DEFAULT NULL COMMENT '召回原因',
            `llm_reason` VARCHAR(255) DEFAULT NULL COMMENT 'LLM重排原因',
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            PRIMARY KEY (`id`),
            KEY `idx_recommendation_trace_record` (`exercise_record_id`),
            KEY `idx_recommendation_trace_selected` (`selected`),
            CONSTRAINT `fk_recommendation_trace_record`
                FOREIGN KEY (`exercise_record_id`) REFERENCES `exercise_record` (`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='推荐两阶段明细表';
    END IF;
END $$

DELIMITER ;

CALL `create_recommendation_trace_table`();

DROP PROCEDURE IF EXISTS `create_recommendation_trace_table`;
