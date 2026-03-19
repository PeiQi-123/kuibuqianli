package com.kuibuqianli.service;

import com.kuibuqianli.dto.ExerciseRecordCreateDTO;
import com.kuibuqianli.dto.RecommendationFeedbackDTO;
import com.kuibuqianli.dto.RecommendationFeedbackResultDTO;

public interface ExerciseRecordService {
    Long createRecord(Long userId, ExerciseRecordCreateDTO dto);

    RecommendationFeedbackResultDTO saveFeedback(Long userId, RecommendationFeedbackDTO dto);
}
