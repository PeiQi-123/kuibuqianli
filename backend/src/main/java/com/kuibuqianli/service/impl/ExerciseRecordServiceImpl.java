package com.kuibuqianli.service.impl;

import com.kuibuqianli.dto.ExerciseRecordCreateDTO;
import com.kuibuqianli.service.ExerciseRecordService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
public class ExerciseRecordServiceImpl implements ExerciseRecordService {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public boolean createRecord(Long userId, ExerciseRecordCreateDTO dto) {
        int result = jdbcTemplate.update(
                "INSERT INTO exercise_record (user_id, motion_id, motion_name, duration, completed) VALUES (?, ?, ?, ?, ?)",
                userId,
                dto.getMotionId(),
                dto.getMotionName(),
                dto.getDuration(),
                Boolean.TRUE.equals(dto.getCompleted())
        );
        return result > 0;
    }
}
