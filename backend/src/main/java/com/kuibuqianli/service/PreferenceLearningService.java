package com.kuibuqianli.service;

import com.kuibuqianli.dto.PreferenceLearningDTO;

import java.util.Map;

public interface PreferenceLearningService {
    PreferenceLearningDTO buildLearningProfile(Long userId);

    Map<String, Object> enrichUserInfo(Long userId, Map<String, Object> userInfo);
}
