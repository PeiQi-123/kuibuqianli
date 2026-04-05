package com.kuibuqianli.service.impl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.kuibuqianli.dao.entity.User;
import com.kuibuqianli.dao.mapper.UserMapper;
import com.kuibuqianli.dto.ReminderLogCreateDTO;
import com.kuibuqianli.dto.ReminderStatusDTO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.util.ReflectionTestUtils;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.LocalTime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ReminderServiceImplTest {

    @Mock
    private UserMapper userMapper;

    @Mock
    private JdbcTemplate jdbcTemplate;

    @InjectMocks
    private ReminderServiceImpl service;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(service, "objectMapper", new ObjectMapper());
    }

    @Test
    void getReminderStatusShouldReturnDefaultsWhenUserDoesNotExist() {
        when(userMapper.selectById(1L)).thenReturn(null);

        ReminderStatusDTO result = service.getReminderStatus(1L);

        assertFalse(result.getRemindEnabled());
        assertEquals(30, result.getRemindInterval());
        assertEquals(3, result.getRemindMaxTimes());
        assertEquals(0, result.getRemindersSentToday());
        assertEquals(0, result.getRemainingRemindersToday());
    }

    @Test
    void getReminderStatusShouldAdjustNextReminderOutOfAvoidPeriod() {
        LocalDateTime baseTime = LocalDateTime.now().withSecond(0).withNano(0).minusMinutes(1);
        LocalDateTime expectedNext = baseTime.plusMinutes(1);
        LocalTime avoidStart = expectedNext.toLocalTime().minusMinutes(1);
        LocalTime avoidEnd = expectedNext.toLocalTime().plusMinutes(20);

        User user = new User();
        user.setId(9L);
        user.setRemindEnabled(true);
        user.setRemindInterval(1);
        user.setRemindMaxTimes(5);
        user.setRemindAvoidTime(
                "[{\"start\":\"" + avoidStart + "\",\"end\":\"" + avoidEnd + "\"}]"
        );

        when(userMapper.selectById(9L)).thenReturn(user);
        when(jdbcTemplate.queryForObject(
                eq("SELECT COUNT(*) FROM remind_log WHERE user_id = ? AND status = 'success' AND actual_time >= ?"),
                eq(Integer.class),
                eq(9L),
                any(Timestamp.class)
        )).thenReturn(2);
        when(jdbcTemplate.queryForObject(
                eq("SELECT COUNT(*) FROM remind_log WHERE user_id = ? AND status = 'skipped' AND actual_time >= ?"),
                eq(Integer.class),
                eq(9L),
                any(Timestamp.class)
        )).thenReturn(1);
        when(jdbcTemplate.queryForObject(
                eq("SELECT MAX(actual_time) FROM remind_log WHERE user_id = ?"),
                eq(Timestamp.class),
                eq(9L)
        )).thenReturn(Timestamp.valueOf(baseTime));
        when(jdbcTemplate.queryForObject(
                eq("SELECT MAX(created_at) FROM exercise_record WHERE user_id = ? AND completed = 1"),
                eq(Timestamp.class),
                eq(9L)
        )).thenReturn(null);

        ReminderStatusDTO result = service.getReminderStatus(9L);

        assertTrue(result.getRemindEnabled());
        assertTrue(result.getInAvoidPeriod());
        assertEquals(2, result.getRemindersSentToday());
        assertEquals(3, result.getRemainingRemindersToday());
        assertEquals(LocalDateTime.of(expectedNext.toLocalDate(), avoidEnd).toString(), result.getNextSuggestedReminderTime());
    }

    @Test
    void createReminderLogShouldDowngradeInvalidStatusToFailed() {
        ReminderLogCreateDTO dto = new ReminderLogCreateDTO();
        dto.setStatus("unexpected");
        dto.setInAvoidPeriod(true);

        when(jdbcTemplate.update(anyString(), eq(5L), any(Timestamp.class), eq(true), eq("failed"))).thenReturn(1);

        boolean saved = service.createReminderLog(5L, dto);

        assertTrue(saved);
        ArgumentCaptor<String> statusCaptor = ArgumentCaptor.forClass(String.class);
        verify(jdbcTemplate).update(anyString(), eq(5L), any(Timestamp.class), eq(true), statusCaptor.capture());
        assertEquals("failed", statusCaptor.getValue());
    }
}
