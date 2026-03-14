package com.kuibuqianli.dto;

import lombok.Data;

@Data
public class ReminderStatusDTO {
    private Boolean remindEnabled;
    private Integer remindInterval;
    private Integer remindMaxTimes;
    private Boolean inAvoidPeriod;
    private Integer remindersSentToday;
    private Integer skippedToday;
    private Integer remainingRemindersToday;
    private String lastReminderTime;
    private String lastExerciseTime;
    private String nextSuggestedReminderTime;
}
