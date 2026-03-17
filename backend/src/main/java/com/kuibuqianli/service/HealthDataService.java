package com.kuibuqianli.service;

import com.kuibuqianli.dto.HealthDataDTO;

public interface HealthDataService {
    HealthDataDTO getUserHealthData(Long userId);
}
