package com.kuibuqianli.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Data
public class HealthDataDTO {
    private BigDecimal height;
    private BigDecimal weight;
    private BigDecimal bmi;
    private String bmiType;
    private Integer age;
    private String gender;
    private Integer totalSessions;
    private Integer completedSessions;
    private Integer totalDurationMinutes;
    private Integer last7DaysSessions;
    private Integer completionRate;
    private List<ExerciseRecordSummaryDTO> recentRecords = new ArrayList<>();

    @Data
    public static class ExerciseRecordSummaryDTO {
        private Long id;
        private String motionName;
        private Integer duration;
        private Boolean completed;
        private String createdAt;
    }
}
