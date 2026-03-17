package com.kuibuqianli.service;

import com.kuibuqianli.dto.ExerciseRecordCreateDTO;

public interface ExerciseRecordService {
    boolean createRecord(Long userId, ExerciseRecordCreateDTO dto);
}
