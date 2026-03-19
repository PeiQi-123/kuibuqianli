package com.kuibuqianli.service.impl;

import com.kuibuqianli.dto.ExerciseRecordCreateDTO;
import com.kuibuqianli.dto.RecommendationFeedbackDTO;
import com.kuibuqianli.dto.RecommendationFeedbackResultDTO;
import com.kuibuqianli.service.ExerciseRecordService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Service;

import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.Set;

@Service
public class ExerciseRecordServiceImpl implements ExerciseRecordService {

    private static final Set<String> ALLOWED_FEEDBACK_TAGS = Set.of("too_easy", "fit", "too_hard", "dislike");

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public Long createRecord(Long userId, ExerciseRecordCreateDTO dto) {
        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbcTemplate.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(
                    "INSERT INTO exercise_record (user_id, motion_id, motion_name, duration, completed) VALUES (?, ?, ?, ?, ?)",
                    Statement.RETURN_GENERATED_KEYS
            );
            ps.setLong(1, userId);
            ps.setString(2, dto.getMotionId());
            ps.setString(3, dto.getMotionName());
            if (dto.getDuration() == null) {
                ps.setNull(4, java.sql.Types.INTEGER);
            } else {
                ps.setInt(4, dto.getDuration());
            }
            ps.setBoolean(5, Boolean.TRUE.equals(dto.getCompleted()));
            return ps;
        }, keyHolder);
        Number key = keyHolder.getKey();
        return key == null ? null : key.longValue();
    }

    @Override
    public RecommendationFeedbackResultDTO saveFeedback(Long userId, RecommendationFeedbackDTO dto) {
        if (dto.getRecordId() == null || dto.getFeedbackTag() == null) {
            return null;
        }
        String feedbackTag = dto.getFeedbackTag().trim().toLowerCase();
        if (!ALLOWED_FEEDBACK_TAGS.contains(feedbackTag)) {
            return null;
        }

        int feedbackScore = switch (feedbackTag) {
            case "fit" -> 3;
            case "too_easy" -> 4;
            case "too_hard" -> 2;
            case "dislike" -> 1;
            default -> 3;
        };

        int result = jdbcTemplate.update(
                "UPDATE exercise_record SET feedback_tag = ?, feedback_score = ?, feedback_at = ? WHERE id = ? AND user_id = ?",
                feedbackTag,
                feedbackScore,
                Timestamp.valueOf(LocalDateTime.now()),
                dto.getRecordId(),
                userId
        );
        if (result <= 0) {
            return null;
        }

        RecommendationFeedbackResultDTO response = new RecommendationFeedbackResultDTO();
        response.setRecordId(dto.getRecordId());
        response.setFeedbackTag(feedbackTag);
        response.setFeedbackScore(feedbackScore);
        response.setLearningDirection(resolveLearningDirection(feedbackTag));
        response.setLearningMessage(resolveLearningMessage(feedbackTag));
        return response;
    }

    private String resolveLearningDirection(String feedbackTag) {
        return switch (feedbackTag) {
            case "too_easy" -> "increase_intensity";
            case "too_hard" -> "decrease_intensity";
            case "dislike" -> "reduce_similar_content";
            default -> "keep_current_level";
        };
    }

    private String resolveLearningMessage(String feedbackTag) {
        return switch (feedbackTag) {
            case "too_easy" -> "已记录你的反馈，后续将提高推荐挑战度。";
            case "too_hard" -> "已记录你的反馈，后续将降低推荐难度。";
            case "dislike" -> "已记录你的反馈，后续将减少相似动作类型。";
            default -> "已记录你的反馈，后续将保持当前推荐强度。";
        };
    }
}
