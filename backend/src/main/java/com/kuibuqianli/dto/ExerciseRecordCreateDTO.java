package com.kuibuqianli.dto;

import lombok.Data;

import java.util.List;

@Data
public class ExerciseRecordCreateDTO {
    private String motionId;
    private String motionName;
    private Integer duration;
    private Boolean completed;
    private String recommendationSummary;
    private List<String> recommendationMatchedItems;
    private List<java.util.Map<String, Object>> recommendationTrace;
}
