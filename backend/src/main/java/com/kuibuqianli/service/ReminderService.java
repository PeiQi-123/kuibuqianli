package com.kuibuqianli.service;

import com.kuibuqianli.dto.ReminderLogCreateDTO;
import com.kuibuqianli.dto.ReminderStatusDTO;

public interface ReminderService {
    ReminderStatusDTO getReminderStatus(Long userId);

    boolean createReminderLog(Long userId, ReminderLogCreateDTO dto);
}
