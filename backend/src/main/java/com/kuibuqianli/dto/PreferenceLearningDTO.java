package com.kuibuqianli.dto;

import lombok.Data;

import java.util.List;
import java.util.Map;

@Data
public class PreferenceLearningDTO {
    private Integer learningWindowDays;
    private Integer totalSessions;
    private Integer completedSessions;
    private Double completionRate;
    private Map<String, Long> feedbackDistribution;
    private Map<String, List<String>> explicitPreferences;
    private Map<String, List<String>> learnedPreferences;
    private Map<String, List<String>> mergedPreferences;
    private String summary;
}
