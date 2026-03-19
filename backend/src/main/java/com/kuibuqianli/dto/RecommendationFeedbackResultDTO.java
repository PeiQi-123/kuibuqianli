package com.kuibuqianli.dto;

import lombok.Data;

@Data
public class RecommendationFeedbackResultDTO {
    private Long recordId;
    private String feedbackTag;
    private Integer feedbackScore;
    private String learningDirection;
    private String learningMessage;
}
