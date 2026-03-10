package com.kuibuqianli.dto;

import lombok.Data;

import java.util.List;

/**
 * User Preference DTO
 * Used for data transfer between frontend and backend
 */
@Data
public class UserPreferenceDTO {
    private String preferenceKey;
    private List<String> preferenceValue; // Use List directly for frontend convenience
}