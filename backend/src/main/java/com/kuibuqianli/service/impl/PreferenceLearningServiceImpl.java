package com.kuibuqianli.service.impl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.kuibuqianli.dao.entity.UserPreference;
import com.kuibuqianli.dao.mapper.UserPreferenceMapper;
import com.kuibuqianli.dto.PreferenceLearningDTO;
import com.kuibuqianli.service.PreferenceLearningService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
public class PreferenceLearningServiceImpl implements PreferenceLearningService {

    private static final int LEARNING_WINDOW_DAYS = 30;

    @Autowired
    private UserPreferenceMapper userPreferenceMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private ObjectMapper objectMapper;

    @Override
    public PreferenceLearningDTO buildLearningProfile(Long userId) {
        Map<String, List<String>> explicitPreferences = loadExplicitPreferences(userId);
        List<ExerciseSample> samples = loadRecentSamples(userId);

        int totalSessions = samples.size();
        int completedSessions = (int) samples.stream().filter(ExerciseSample::completed).count();
        double completionRate = totalSessions == 0 ? 0D : (double) completedSessions / totalSessions;
        Map<String, Long> feedbackDistribution = buildFeedbackDistribution(samples);

        Map<String, Map<String, Double>> scores = initScoreMap();
        for (ExerciseSample sample : samples) {
            double weight = calculateWeight(sample);
            addScores(scores.get("body_part"), inferBodyParts(sample.motionName()), weight);
            addScores(scores.get("sport_type"), inferSportTypes(sample.motionName()), weight);
            addScores(scores.get("scene"), inferScenes(sample.createdAt()), weight);
            addScores(scores.get("duration"), List.of(inferDurationBucket(sample.durationSeconds())), weight);
            addScores(scores.get("pace"), List.of(inferPace(sample.durationSeconds())), weight);
        }

        Map<String, List<String>> learnedPreferences = new LinkedHashMap<>();
        learnedPreferences.put("body_part", topValues(scores.get("body_part"), 3));
        learnedPreferences.put("sport_type", topValues(scores.get("sport_type"), 3));
        learnedPreferences.put("scene", topValues(scores.get("scene"), 2));
        learnedPreferences.put("duration", topValues(scores.get("duration"), 2));
        learnedPreferences.put("pace", topValues(scores.get("pace"), 1));
        learnedPreferences.put("difficulty", List.of(inferDifficulty(completionRate, samples, feedbackDistribution)));

        Map<String, List<String>> mergedPreferences = mergePreferences(explicitPreferences, learnedPreferences);

        PreferenceLearningDTO dto = new PreferenceLearningDTO();
        dto.setLearningWindowDays(LEARNING_WINDOW_DAYS);
        dto.setTotalSessions(totalSessions);
        dto.setCompletedSessions(completedSessions);
        dto.setCompletionRate(Math.round(completionRate * 1000D) / 1000D);
        dto.setFeedbackDistribution(feedbackDistribution);
        dto.setExplicitPreferences(explicitPreferences);
        dto.setLearnedPreferences(learnedPreferences);
        dto.setMergedPreferences(mergedPreferences);
        dto.setSummary(buildSummary(learnedPreferences, totalSessions, completionRate, feedbackDistribution));
        return dto;
    }

    @Override
    public Map<String, Object> enrichUserInfo(Long userId, Map<String, Object> userInfo) {
        Map<String, Object> enriched = new LinkedHashMap<>();
        if (userInfo != null) {
            enriched.putAll(userInfo);
        }

        PreferenceLearningDTO learning = buildLearningProfile(userId);
        enriched.put("preference_learning_summary", learning.getSummary());
        enriched.put("explicit_preferences", learning.getExplicitPreferences());
        enriched.put("learned_preferences", learning.getLearnedPreferences());
        enriched.put("merged_preferences", learning.getMergedPreferences());
        enriched.put("preferred_body_parts", learning.getMergedPreferences().getOrDefault("body_part", Collections.emptyList()));
        enriched.put("preferred_sport_types", learning.getMergedPreferences().getOrDefault("sport_type", Collections.emptyList()));
        enriched.put("preferred_scenes", learning.getMergedPreferences().getOrDefault("scene", Collections.emptyList()));
        enriched.put("preferred_durations", learning.getMergedPreferences().getOrDefault("duration", Collections.emptyList()));
        enriched.put("preferred_pace", learning.getMergedPreferences().getOrDefault("pace", Collections.emptyList()));
        enriched.put("preferred_difficulty", learning.getMergedPreferences().getOrDefault("difficulty", Collections.emptyList()));
        enriched.put("completed_sessions_30d", learning.getCompletedSessions());
        enriched.put("completion_rate_30d", learning.getCompletionRate());
        return enriched;
    }

    private Map<String, List<String>> loadExplicitPreferences(Long userId) {
        List<UserPreference> records = userPreferenceMapper.findByUserId(userId);
        Map<String, List<String>> result = new LinkedHashMap<>();
        for (UserPreference record : records) {
            result.put(record.getPreferenceKey(), parseStringList(record.getPreferenceValue()));
        }
        return result;
    }

    private List<ExerciseSample> loadRecentSamples(Long userId) {
        LocalDateTime threshold = LocalDateTime.now().minusDays(LEARNING_WINDOW_DAYS);
        return jdbcTemplate.query(
                "SELECT motion_name, duration, completed, created_at, feedback_tag, feedback_score FROM exercise_record WHERE user_id = ? AND created_at >= ? ORDER BY created_at DESC",
                (rs, rowNum) -> mapSample(rs),
                userId,
                Timestamp.valueOf(threshold)
        );
    }

    private ExerciseSample mapSample(ResultSet rs) throws SQLException {
        Timestamp timestamp = rs.getTimestamp("created_at");
        return new ExerciseSample(
                rs.getString("motion_name"),
                rs.getInt("duration"),
                rs.getBoolean("completed"),
                timestamp == null ? LocalDateTime.now() : timestamp.toLocalDateTime(),
                rs.getString("feedback_tag"),
                rs.getObject("feedback_score") == null ? null : rs.getInt("feedback_score")
        );
    }

    private Map<String, Map<String, Double>> initScoreMap() {
        Map<String, Map<String, Double>> scores = new LinkedHashMap<>();
        scores.put("body_part", new LinkedHashMap<>());
        scores.put("sport_type", new LinkedHashMap<>());
        scores.put("scene", new LinkedHashMap<>());
        scores.put("duration", new LinkedHashMap<>());
        scores.put("pace", new LinkedHashMap<>());
        return scores;
    }

    private double calculateWeight(ExerciseSample sample) {
        long days = Math.max(Duration.between(sample.createdAt(), LocalDateTime.now()).toDays(), 0);
        double recencyWeight = days <= 7 ? 1.0 : days <= 14 ? 0.8 : days <= 21 ? 0.65 : 0.5;
        double completionWeight = sample.completed() ? 1.0 : 0.35;
        double durationWeight = sample.durationSeconds() >= 300 ? 1.15 : sample.durationSeconds() >= 180 ? 1.0 : 0.85;
        double feedbackWeight = switch (sample.feedbackTag() == null ? "" : sample.feedbackTag()) {
            case "fit" -> 1.25;
            case "too_easy" -> 1.1;
            case "too_hard" -> 0.8;
            case "dislike" -> 0.4;
            default -> 1.0;
        };
        if (sample.feedbackScore() != null) {
            feedbackWeight *= (0.7 + sample.feedbackScore() * 0.15);
        }
        return recencyWeight * completionWeight * durationWeight * feedbackWeight;
    }

    private void addScores(Map<String, Double> scoreMap, List<String> values, double weight) {
        for (String value : values) {
            if (value == null || value.isBlank()) {
                continue;
            }
            scoreMap.merge(value, weight, Double::sum);
        }
    }

    private List<String> topValues(Map<String, Double> scoreMap, int limit) {
        return scoreMap.entrySet().stream()
                .filter(entry -> entry.getValue() >= 0.6)
                .sorted(Map.Entry.<String, Double>comparingByValue(Comparator.reverseOrder()))
                .limit(limit)
                .map(Map.Entry::getKey)
                .collect(Collectors.toList());
    }

    private List<String> inferBodyParts(String motionName) {
        String text = normalize(motionName);
        List<String> parts = new ArrayList<>();
        if (containsAny(text, "颈", "脖", "收下巴")) parts.add("颈部");
        if (containsAny(text, "肩", "肩周", "耸肩")) parts.add("肩部");
        if (containsAny(text, "腰", "腰椎")) parts.add("腰部");
        if (containsAny(text, "背", "脊", "胸椎")) parts.add("背部");
        if (containsAny(text, "腿", "膝", "踝", "大腿", "小腿", "下肢", "臀")) parts.add("腿部");
        if (containsAny(text, "腕", "手", "指", "前臂", "小臂")) parts.add("手腕");
        if (parts.isEmpty()) {
            parts.add("全身");
        }
        return distinct(parts);
    }

    private List<String> inferSportTypes(String motionName) {
        String text = normalize(motionName);
        List<String> types = new ArrayList<>();
        if (containsAny(text, "呼吸")) types.add("深呼吸");
        if (containsAny(text, "眼", "视")) types.add("眼部放松");
        if (containsAny(text, "按摩", "按压", "放松")) types.add("按摩放松");
        if (containsAny(text, "矫正", "收下巴", "体态")) types.add("体态矫正");
        if (containsAny(text, "绕环", "旋转", "活动")) types.add("关节活动");
        if (containsAny(text, "摆", "动态")) types.add("动态拉伸");
        if (containsAny(text, "拉伸", "伸展")) types.add("静态拉伸");
        if (containsAny(text, "抬腿", "深蹲", "提踵", "力量")) types.add("微力量锻炼");
        if (types.isEmpty()) {
            types.add("静态拉伸");
        }
        return distinct(types);
    }

    private List<String> inferScenes(LocalDateTime createdAt) {
        int hour = createdAt.getHour();
        if (hour >= 6 && hour < 9) {
            return List.of("起床唤醒", "通勤间隙");
        }
        if (hour >= 9 && hour < 12) {
            return List.of("办公久坐");
        }
        if (hour >= 12 && hour < 14) {
            return List.of("饭后消食");
        }
        if (hour >= 14 && hour < 18) {
            return List.of("办公久坐", "长时间用手");
        }
        if (hour >= 18 && hour < 21) {
            return List.of("通勤间隙");
        }
        return List.of("睡前放松");
    }

    private String inferDurationBucket(int durationSeconds) {
        int minutes = Math.max(1, (int) Math.round(durationSeconds / 60.0));
        List<Integer> supported = List.of(1, 2, 3, 4, 5, 10);
        int nearest = supported.get(0);
        int minDiff = Math.abs(minutes - nearest);
        for (int value : supported) {
            int diff = Math.abs(minutes - value);
            if (diff < minDiff) {
                minDiff = diff;
                nearest = value;
            }
        }
        return nearest + "分钟";
    }

    private String inferPace(int durationSeconds) {
        if (durationSeconds <= 90) {
            return "快";
        }
        if (durationSeconds <= 240) {
            return "中";
        }
        return "慢";
    }

    private String inferDifficulty(double completionRate, List<ExerciseSample> samples, Map<String, Long> feedbackDistribution) {
        double avgDuration = samples.stream().mapToInt(ExerciseSample::durationSeconds).average().orElse(60);
        long tooEasy = feedbackDistribution.getOrDefault("too_easy", 0L);
        long tooHard = feedbackDistribution.getOrDefault("too_hard", 0L);
        long dislike = feedbackDistribution.getOrDefault("dislike", 0L);
        long fit = feedbackDistribution.getOrDefault("fit", 0L);
        if (tooHard > tooEasy && tooHard >= fit) {
            return "零基础";
        }
        if (tooEasy > 0 && tooEasy >= tooHard && completionRate >= 0.7) {
            return "有难度";
        }
        if (dislike > fit && dislike > tooEasy) {
            return "零基础";
        }
        if (completionRate >= 0.85 && avgDuration >= 240) {
            return "有难度";
        }
        if (completionRate >= 0.65) {
            return "入门级";
        }
        return "零基础";
    }

    private Map<String, List<String>> mergePreferences(
            Map<String, List<String>> explicitPreferences,
            Map<String, List<String>> learnedPreferences
    ) {
        Map<String, List<String>> merged = new LinkedHashMap<>();
        LinkedHashSet<String> keys = new LinkedHashSet<>();
        keys.addAll(explicitPreferences.keySet());
        keys.addAll(learnedPreferences.keySet());
        for (String key : keys) {
            LinkedHashSet<String> values = new LinkedHashSet<>();
            values.addAll(explicitPreferences.getOrDefault(key, Collections.emptyList()));
            values.addAll(learnedPreferences.getOrDefault(key, Collections.emptyList()));
            merged.put(key, new ArrayList<>(values));
        }
        return merged;
    }

    private String buildSummary(Map<String, List<String>> learnedPreferences, int totalSessions, double completionRate, Map<String, Long> feedbackDistribution) {
        List<String> parts = learnedPreferences.getOrDefault("body_part", Collections.emptyList());
        List<String> types = learnedPreferences.getOrDefault("sport_type", Collections.emptyList());
        List<String> durations = learnedPreferences.getOrDefault("duration", Collections.emptyList());
        List<String> scenes = learnedPreferences.getOrDefault("scene", Collections.emptyList());
        String feedbackSummary = buildFeedbackSummary(feedbackDistribution);
        return String.format(
                Locale.ROOT,
                "近%d天共分析%d次训练，完成率%.0f%%。系统学习到你更偏好%s部位、%s类型、%s时长，并主要在%s场景下进行微运动。%s",
                LEARNING_WINDOW_DAYS,
                totalSessions,
                completionRate * 100,
                joinOrDefault(parts, "全身放松"),
                joinOrDefault(types, "静态拉伸"),
                joinOrDefault(durations, "3-5分钟"),
                joinOrDefault(scenes, "办公久坐"),
                feedbackSummary
        );
    }

    private Map<String, Long> buildFeedbackDistribution(List<ExerciseSample> samples) {
        return samples.stream()
                .map(ExerciseSample::feedbackTag)
                .filter(tag -> tag != null && !tag.isBlank())
                .collect(Collectors.groupingBy(tag -> tag, LinkedHashMap::new, Collectors.counting()));
    }

    private String buildFeedbackSummary(Map<String, Long> feedbackDistribution) {
        if (feedbackDistribution.isEmpty()) {
            return "当前尚未积累足够的推荐反馈，系统将继续根据训练完成情况学习。";
        }
        long fit = feedbackDistribution.getOrDefault("fit", 0L);
        long tooEasy = feedbackDistribution.getOrDefault("too_easy", 0L);
        long tooHard = feedbackDistribution.getOrDefault("too_hard", 0L);
        long dislike = feedbackDistribution.getOrDefault("dislike", 0L);
        if (tooEasy >= tooHard && tooEasy >= fit) {
            return "最近反馈显示你更希望提升动作挑战度，后续推荐会适当增强难度。";
        }
        if (tooHard > tooEasy && tooHard >= fit) {
            return "最近反馈显示当前动作略难，后续推荐会优先降低动作复杂度和节奏。";
        }
        if (dislike > fit) {
            return "最近反馈显示你对部分动作接受度较低，系统会减少类似动作出现频率。";
        }
        return "最近反馈显示当前推荐整体匹配度较好，系统会保持相近推荐策略并微调优化。";
    }

    private List<String> parseStringList(String json) {
        if (json == null || json.isBlank()) {
            return Collections.emptyList();
        }
        try {
            return objectMapper.readValue(
                    json,
                    objectMapper.getTypeFactory().constructCollectionType(List.class, String.class)
            );
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    private boolean containsAny(String source, String... keywords) {
        for (String keyword : keywords) {
            if (source.contains(normalize(keyword))) {
                return true;
            }
        }
        return false;
    }

    private String normalize(String value) {
        return value == null ? "" : value.replaceAll("\\s+", "").toLowerCase(Locale.ROOT);
    }

    private List<String> distinct(List<String> input) {
        return input.stream().filter(Objects::nonNull).distinct().collect(Collectors.toList());
    }

    private String joinOrDefault(List<String> values, String fallback) {
        return values == null || values.isEmpty() ? fallback : String.join("、", values);
    }

    private record ExerciseSample(
            String motionName,
            int durationSeconds,
            boolean completed,
            LocalDateTime createdAt,
            String feedbackTag,
            Integer feedbackScore
    ) {
    }
}
