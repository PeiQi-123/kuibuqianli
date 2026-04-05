package com.kuibuqianli.service.impl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.kuibuqianli.dto.RecommendationFeedbackDTO;
import com.kuibuqianli.dto.RecommendationFeedbackResultDTO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ExerciseRecordServiceImplTest {

    @Mock
    private JdbcTemplate jdbcTemplate;

    @InjectMocks
    private ExerciseRecordServiceImpl service;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(service, "objectMapper", new ObjectMapper());
    }

    @Test
    void saveFeedbackShouldNormalizeTagAndReturnLearningResult() {
        RecommendationFeedbackDTO dto = new RecommendationFeedbackDTO();
        dto.setRecordId(12L);
        dto.setFeedbackTag(" TOO_EASY ");

        when(jdbcTemplate.update(
                anyString(),
                eq("too_easy"),
                eq(4),
                any(),
                eq(12L),
                eq(7L)
        )).thenReturn(1);

        RecommendationFeedbackResultDTO result = service.saveFeedback(7L, dto);

        assertNotNull(result);
        assertEquals(12L, result.getRecordId());
        assertEquals("too_easy", result.getFeedbackTag());
        assertEquals(4, result.getFeedbackScore());
        assertEquals("increase_intensity", result.getLearningDirection());
    }

    @Test
    void saveFeedbackShouldRejectUnsupportedTagWithoutUpdatingDatabase() {
        RecommendationFeedbackDTO dto = new RecommendationFeedbackDTO();
        dto.setRecordId(12L);
        dto.setFeedbackTag("unknown");

        RecommendationFeedbackResultDTO result = service.saveFeedback(7L, dto);

        assertNull(result);
        verify(jdbcTemplate, never()).update(anyString(), any(), any(), any(), anyLong(), anyLong());
    }

    @Test
    void saveFeedbackShouldReturnNullWhenRecordUpdateFails() {
        RecommendationFeedbackDTO dto = new RecommendationFeedbackDTO();
        dto.setRecordId(12L);
        dto.setFeedbackTag("fit");

        when(jdbcTemplate.update(
                anyString(),
                eq("fit"),
                eq(3),
                any(),
                eq(12L),
                eq(7L)
        )).thenReturn(0);

        RecommendationFeedbackResultDTO result = service.saveFeedback(7L, dto);

        assertNull(result);
    }
}
