package com.kuibuqianli.service.impl;

import com.kuibuqianli.common.exception.BusinessException;
import com.kuibuqianli.dao.entity.User;
import com.kuibuqianli.dao.mapper.UserMapper;
import com.kuibuqianli.dto.HealthDataDTO;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class HealthDataServiceImplTest {

    @Mock
    private UserMapper userMapper;

    @Mock
    private JdbcTemplate jdbcTemplate;

    @Test
    void getUserHealthDataShouldComputeSummaryAndBmiFromRecords() throws Exception {
        HealthDataServiceImpl service = new HealthDataServiceImpl();
        ReflectionTestUtils.setField(service, "userMapper", userMapper);
        ReflectionTestUtils.setField(service, "jdbcTemplate", jdbcTemplate);

        User user = new User();
        user.setId(7L);
        user.setHeight(new BigDecimal("170"));
        user.setWeight(new BigDecimal("65"));
        user.setAge(24);
        user.setGender("male");

        when(userMapper.selectById(7L)).thenReturn(user);
        when(jdbcTemplate.queryForMap(anyString(), eq(7L))).thenReturn(Map.of(
                "totalSessions", 5,
                "completedSessions", 4,
                "totalDurationSeconds", 900,
                "last7DaysSessions", 3
        ));
        when(jdbcTemplate.query(
                anyString(),
                org.mockito.ArgumentMatchers.<RowMapper<HealthDataDTO.ExerciseRecordSummaryDTO>>any(),
                eq(7L)
        )).thenAnswer(invocation -> {
            @SuppressWarnings("unchecked")
            RowMapper<HealthDataDTO.ExerciseRecordSummaryDTO> mapper = invocation.getArgument(1);
            ResultSet rs = mock(ResultSet.class);
            when(rs.getLong("id")).thenReturn(101L);
            when(rs.getString("motion_name")).thenReturn("neck stretch");
            when(rs.getInt("duration")).thenReturn(180);
            when(rs.getBoolean("completed")).thenReturn(true);
            when(rs.getTimestamp("created_at")).thenReturn(Timestamp.valueOf(LocalDateTime.of(2026, 4, 5, 10, 30)));
            return List.of(mapper.mapRow(rs, 0));
        });

        HealthDataDTO result = service.getUserHealthData(7L);

        assertEquals(new BigDecimal("22.49"), result.getBmi());
        assertEquals("\u6b63\u5e38", result.getBmiType());
        assertEquals(5, result.getTotalSessions());
        assertEquals(4, result.getCompletedSessions());
        assertEquals(15, result.getTotalDurationMinutes());
        assertEquals(3, result.getLast7DaysSessions());
        assertEquals(80, result.getCompletionRate());
        assertEquals(1, result.getRecentRecords().size());
        assertEquals("neck stretch", result.getRecentRecords().get(0).getMotionName());
        assertEquals("2026-04-05 10:30", result.getRecentRecords().get(0).getCreatedAt());
    }

    @Test
    void getUserHealthDataShouldThrowWhenUserDoesNotExist() {
        HealthDataServiceImpl service = new HealthDataServiceImpl();
        ReflectionTestUtils.setField(service, "userMapper", userMapper);
        ReflectionTestUtils.setField(service, "jdbcTemplate", jdbcTemplate);

        when(userMapper.selectById(99L)).thenReturn(null);

        assertThrows(BusinessException.class, () -> service.getUserHealthData(99L));
    }
}
