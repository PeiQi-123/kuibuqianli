package com.kuibuqianli.dto;

import lombok.Data;

@Data
public class ExerciseRecordCreateDTO {
    private String motionId;
    private String motionName;
    private Integer duration;
    private Boolean completed;
}
