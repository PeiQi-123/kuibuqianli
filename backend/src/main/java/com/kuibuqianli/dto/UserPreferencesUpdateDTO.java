package com.kuibuqianli.dto;

import lombok.Data;

import java.util.List;

/**
 * Batch Update User Preferences DTO
 */
@Data
public class UserPreferencesUpdateDTO {
    private List<UserPreferenceDTO> preferences;
}