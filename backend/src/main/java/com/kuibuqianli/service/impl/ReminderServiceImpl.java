package com.kuibuqianli.service.impl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.kuibuqianli.dao.entity.User;
import com.kuibuqianli.dao.mapper.UserMapper;
import com.kuibuqianli.dto.ReminderLogCreateDTO;
import com.kuibuqianli.dto.ReminderStatusDTO;
import com.kuibuqianli.service.ReminderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.Collections;
import java.util.List;
import java.util.Map;

@Service
public class ReminderServiceImpl implements ReminderService {

    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ISO_LOCAL_DATE_TIME;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private ObjectMapper objectMapper;

    @Override
    public ReminderStatusDTO getReminderStatus(Long userId) {
        User user = userMapper.selectById(userId);
        ReminderStatusDTO dto = new ReminderStatusDTO();
        if (user == null) {
            dto.setRemindEnabled(false);
            dto.setRemindInterval(30);
            dto.setRemindMaxTimes(3);
            dto.setInAvoidPeriod(false);
            dto.setRemindersSentToday(0);
            dto.setSkippedToday(0);
            dto.setRemainingRemindersToday(0);
            return dto;
        }

        boolean remindEnabled = !Boolean.FALSE.equals(user.getRemindEnabled());
        int remindInterval = user.getRemindInterval() != null ? user.getRemindInterval() : 30;
        int remindMaxTimes = user.getRemindMaxTimes() != null ? user.getRemindMaxTimes() : 3;
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime todayStart = LocalDate.now().atStartOfDay();

        int remindersSentToday = queryCount(
                "SELECT COUNT(*) FROM remind_log WHERE user_id = ? AND status = 'success' AND actual_time >= ?",
                userId,
                Timestamp.valueOf(todayStart)
        );
        int skippedToday = queryCount(
                "SELECT COUNT(*) FROM remind_log WHERE user_id = ? AND status = 'skipped' AND actual_time >= ?",
                userId,
                Timestamp.valueOf(todayStart)
        );

        LocalDateTime lastReminderTime = queryTime(
                "SELECT MAX(actual_time) FROM remind_log WHERE user_id = ?",
                userId
        );
        LocalDateTime lastExerciseTime = queryTime(
                "SELECT MAX(created_at) FROM exercise_record WHERE user_id = ? AND completed = 1",
                userId
        );

        boolean inAvoidPeriod = isInAvoidPeriod(now.toLocalTime(), parseAvoidTimes(user.getRemindAvoidTime()));
        LocalDateTime baseTime = lastExerciseTime;
        if (baseTime == null || (lastReminderTime != null && lastReminderTime.isAfter(baseTime))) {
            baseTime = lastReminderTime;
        }
        if (baseTime == null) {
            baseTime = now;
        }

        LocalDateTime nextSuggestedReminderTime = baseTime.plusMinutes(remindInterval);
        LocalDateTime quietAdjustedTime = adjustToAvoidPeriods(nextSuggestedReminderTime, parseAvoidTimes(user.getRemindAvoidTime()));

        dto.setRemindEnabled(remindEnabled);
        dto.setRemindInterval(remindInterval);
        dto.setRemindMaxTimes(remindMaxTimes);
        dto.setInAvoidPeriod(inAvoidPeriod);
        dto.setRemindersSentToday(remindersSentToday);
        dto.setSkippedToday(skippedToday);
        dto.setRemainingRemindersToday(Math.max(remindMaxTimes - remindersSentToday, 0));
        dto.setLastReminderTime(format(lastReminderTime));
        dto.setLastExerciseTime(format(lastExerciseTime));
        dto.setNextSuggestedReminderTime(format(quietAdjustedTime));
        return dto;
    }

    @Override
    public boolean createReminderLog(Long userId, ReminderLogCreateDTO dto) {
        String status = dto.getStatus() == null ? "success" : dto.getStatus().trim().toLowerCase();
        if (!List.of("success", "failed", "skipped").contains(status)) {
            status = "failed";
        }

        int result = jdbcTemplate.update(
                "INSERT INTO remind_log (user_id, actual_time, in_avoid_period, status) VALUES (?, ?, ?, ?)",
                userId,
                Timestamp.valueOf(LocalDateTime.now()),
                Boolean.TRUE.equals(dto.getInAvoidPeriod()),
                status
        );
        return result > 0;
    }

    private int queryCount(String sql, Object... args) {
        Integer count = jdbcTemplate.queryForObject(sql, Integer.class, args);
        return count != null ? count : 0;
    }

    private LocalDateTime queryTime(String sql, Object... args) {
        Timestamp timestamp = jdbcTemplate.queryForObject(sql, Timestamp.class, args);
        return timestamp != null ? timestamp.toLocalDateTime() : null;
    }

    private String format(LocalDateTime value) {
        return value == null ? null : value.format(DATE_TIME_FORMATTER);
    }

    private List<Map<String, String>> parseAvoidTimes(String remindAvoidTime) {
        if (remindAvoidTime == null || remindAvoidTime.isBlank()) {
            return Collections.emptyList();
        }
        try {
            return objectMapper.readValue(
                    remindAvoidTime,
                    objectMapper.getTypeFactory().constructCollectionType(List.class, Map.class)
            );
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    private boolean isInAvoidPeriod(LocalTime now, List<Map<String, String>> avoidTimes) {
        for (Map<String, String> period : avoidTimes) {
            LocalTime start = parseTime(period.get("start"));
            LocalTime end = parseTime(period.get("end"));
            if (start == null || end == null) {
                continue;
            }
            if (covers(start, end, now)) {
                return true;
            }
        }
        return false;
    }

    private LocalDateTime adjustToAvoidPeriods(LocalDateTime time, List<Map<String, String>> avoidTimes) {
        LocalDateTime adjusted = time;
        boolean changed;
        do {
            changed = false;
            for (Map<String, String> period : avoidTimes) {
                LocalTime start = parseTime(period.get("start"));
                LocalTime end = parseTime(period.get("end"));
                if (start == null || end == null) {
                    continue;
                }
                if (covers(start, end, adjusted.toLocalTime())) {
                    adjusted = moveToPeriodEnd(adjusted, start, end);
                    changed = true;
                    break;
                }
            }
        } while (changed);
        return adjusted;
    }

    private LocalDateTime moveToPeriodEnd(LocalDateTime current, LocalTime start, LocalTime end) {
        if (!start.isAfter(end)) {
            return LocalDateTime.of(current.toLocalDate(), end);
        }
        if (!current.toLocalTime().isBefore(start)) {
            return LocalDateTime.of(current.toLocalDate().plusDays(1), end);
        }
        return LocalDateTime.of(current.toLocalDate(), end);
    }

    private boolean covers(LocalTime start, LocalTime end, LocalTime now) {
        if (start.equals(end)) {
            return true;
        }
        if (start.isBefore(end)) {
            return !now.isBefore(start) && now.isBefore(end);
        }
        return !now.isBefore(start) || now.isBefore(end);
    }

    private LocalTime parseTime(String value) {
        try {
            return value == null ? null : LocalTime.parse(value.trim());
        } catch (Exception e) {
            return null;
        }
    }
}
