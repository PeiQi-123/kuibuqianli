package com.kuibuqianli.service;

import com.kuibuqianli.dto.ExerciseRecordCreateDTO;
import com.kuibuqianli.dto.RecommendationFeedbackDTO;

public interface ExerciseRecordService {
    Long createRecord(Long userId, ExerciseRecordCreateDTO dto);

    boolean saveFeedback(Long userId, RecommendationFeedbackDTO dto);
}
