package com.kuibuqianli.service.impl;

import com.kuibuqianli.common.constants.ErrorCode;
import com.kuibuqianli.common.exception.BusinessException;
import com.kuibuqianli.dao.entity.User;
import com.kuibuqianli.dao.mapper.UserMapper;
import com.kuibuqianli.dto.HealthDataDTO;
import com.kuibuqianli.service.HealthDataService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

@Service
public class HealthDataServiceImpl implements HealthDataService {

    private static final DateTimeFormatter RECORD_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public HealthDataDTO getUserHealthData(Long userId) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException(ErrorCode.NOT_FOUND_ERROR);
        }

        HealthDataDTO dto = new HealthDataDTO();
        dto.setHeight(user.getHeight());
        dto.setWeight(user.getWeight());
        dto.setAge(user.getAge());
        dto.setGender(user.getGender());

        BigDecimal bmi = resolveBmi(user);
        dto.setBmi(bmi);
        dto.setBmiType(resolveBmiType(user, bmi));

        Map<String, Object> summary = jdbcTemplate.queryForMap(
                "SELECT COUNT(*) AS totalSessions, " +
                        "COALESCE(SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END), 0) AS completedSessions, " +
                        "COALESCE(SUM(duration), 0) AS totalDurationSeconds, " +
                        "COALESCE(SUM(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 ELSE 0 END), 0) AS last7DaysSessions " +
                        "FROM exercise_record WHERE user_id = ?",
                userId
        );

        int totalSessions = getInt(summary.get("totalSessions"));
        int completedSessions = getInt(summary.get("completedSessions"));
        int totalDurationSeconds = getInt(summary.get("totalDurationSeconds"));
        int last7DaysSessions = getInt(summary.get("last7DaysSessions"));

        dto.setTotalSessions(totalSessions);
        dto.setCompletedSessions(completedSessions);
        dto.setTotalDurationMinutes(totalDurationSeconds / 60);
        dto.setLast7DaysSessions(last7DaysSessions);
        dto.setCompletionRate(totalSessions == 0 ? 0 : (completedSessions * 100 / totalSessions));

        List<HealthDataDTO.ExerciseRecordSummaryDTO> recentRecords = jdbcTemplate.query(
                "SELECT id, motion_name, duration, completed, created_at " +
                        "FROM exercise_record WHERE user_id = ? ORDER BY created_at DESC LIMIT 7",
                (rs, rowNum) -> mapRecord(rs),
                userId
        );
        dto.setRecentRecords(recentRecords);
        return dto;
    }

    private HealthDataDTO.ExerciseRecordSummaryDTO mapRecord(ResultSet rs) throws SQLException {
        HealthDataDTO.ExerciseRecordSummaryDTO record = new HealthDataDTO.ExerciseRecordSummaryDTO();
        record.setId(rs.getLong("id"));
        record.setMotionName(rs.getString("motion_name"));
        record.setDuration(rs.getInt("duration"));
        record.setCompleted(rs.getBoolean("completed"));
        LocalDateTime createdAt = rs.getTimestamp("created_at").toLocalDateTime();
        record.setCreatedAt(createdAt.format(RECORD_TIME_FORMATTER));
        return record;
    }

    private BigDecimal resolveBmi(User user) {
        if (user.getBmi() != null) {
            return user.getBmi();
        }
        if (user.getHeight() == null || user.getWeight() == null || BigDecimal.ZERO.compareTo(user.getHeight()) == 0) {
            return null;
        }
        BigDecimal heightMeter = user.getHeight().divide(BigDecimal.valueOf(100), 4, RoundingMode.HALF_UP);
        return user.getWeight().divide(heightMeter.multiply(heightMeter), 2, RoundingMode.HALF_UP);
    }

    private String resolveBmiType(User user, BigDecimal bmi) {
        if (user.getBmiType() != null && !user.getBmiType().isEmpty()) {
            return user.getBmiType();
        }
        if (bmi == null) {
            return null;
        }
        double bmiValue = bmi.doubleValue();
        if (bmiValue < 18.5) {
            return "偏瘦";
        }
        if (bmiValue < 24.0) {
            return "正常";
        }
        if (bmiValue < 28.0) {
            return "偏胖";
        }
        return "肥胖";
    }

    private int getInt(Object value) {
        if (value == null) {
            return 0;
        }
        return ((Number) value).intValue();
    }
}
