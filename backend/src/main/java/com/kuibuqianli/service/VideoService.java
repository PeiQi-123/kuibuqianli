package com.kuibuqianli.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import java.io.*;
import java.nio.file.*;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class VideoService {

    private static final String VIDEO_DIR = "D:/teach/kuibuqianli/kuibuqianli/video";
    private static final String OUTPUT_DIR = "D:/teach/kuibuqianli/kuibuqianli/video/output";

    // 简单的中文关键词和文件名关键词映射，用于从步骤文本中推断对应片段
    // 比如: "坐姿脚尖点地" 会匹配到包含 "脚" 或 "腿" 的文件名
    private static final Map<String, String> STEP_KEYWORDS = Map.ofEntries(
            Map.entry("颈", "颈"),
            Map.entry("肩", "肩"),
            Map.entry("腰", "腰"),
            Map.entry("背", "背"),
            Map.entry("胸", "胸"),
            Map.entry("腹", "腹"),
            Map.entry("腿", "腿"),
            Map.entry("脚", "脚"),
            Map.entry("踮", "踮"),
            Map.entry("走路", "走路"),
            Map.entry("小腿", "小腿"),
            Map.entry("手腕", "手腕"),
            Map.entry("手臂", "手臂"),
            Map.entry("手指", "手指"),
            Map.entry("手肘", "手肘"),
            Map.entry("手", "手"),
            Map.entry("臂", "臂"),
            Map.entry("呼吸", "呼吸")
    );

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public List<String> getAvailableVideos() {
        return getAvailableVideos(null, null);
    }

    public List<String> getAvailableVideos(Long userId, String bodyPart) {
        try {
            Files.createDirectories(Paths.get(OUTPUT_DIR));
            List<String> videos = Files.list(Paths.get(VIDEO_DIR))
                    .filter(Files::isRegularFile)
                    .filter(p -> p.toString().endsWith(".mp4"))
                    .map(p -> p.getFileName().toString())
                    .collect(Collectors.toList());

            if (userId == null) {
                return videos;
            }
            return sortVideosByPreference(videos, userId, bodyPart);
        } catch (IOException e) {
            return Collections.emptyList();
        }
    }

    public String findVideoByKeyword(String keyword) {
        try {
            return Files.list(Paths.get(VIDEO_DIR))
                    .filter(Files::isRegularFile)
                    .filter(p -> p.toString().endsWith(".mp4"))
                    .filter(p -> p.getFileName().toString().contains(keyword))
                    .map(p -> p.toString())
                    .findFirst()
                    .orElse(null);
        } catch (IOException e) {
            return null;
        }
    }

    /**
     * 根据关键词列表拼接视频（保留原有逻辑，方便直接按文件名关键字调用）
     */
    public String concatenateVideos(List<String> videoKeywords, String outputName) {
        try {
            Files.createDirectories(Paths.get(OUTPUT_DIR));
            
            // 查找所有匹配的视频文件
            List<String> videoPaths = new ArrayList<>();
            for (String keyword : videoKeywords) {
                String path = findVideoByKeyword(keyword);
                if (path != null) {
                    videoPaths.add(path);
                }
            }

            if (videoPaths.isEmpty()) {
                return null;
            }

            return concatenateVideoFiles(videoPaths, outputName);

        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    /**
     * 按微运动的步骤文本自动选择对应视频片段，并拼接为一个完整视频。
     *
     * 调用方式示例：传入 AI 返回的 steps 列表和 motionId（如 "motion_001"）。
     */
    public String concatenateVideosBySteps(List<String> steps, String motionId) {
        if (steps == null || steps.isEmpty()) {
            return null;
        }

        List<String> videoPaths = new ArrayList<>();
        for (int i = 0; i < steps.size(); i++) {
            String stepText = steps.get(i);
            String path = findVideoForStep(stepText, i + 1, motionId);
            if (path != null) {
                videoPaths.add(path);
            }
        }

        if (videoPaths.isEmpty()) {
            return null;
        }

        String outputName = motionId + "_combined";
        return concatenateVideoFiles(videoPaths, outputName);
    }

    /**
     * 实际执行 FFmpeg 拼接逻辑的通用方法，输入为已经解析好的绝对路径列表。
     */
    public String concatenateVideoFiles(List<String> videoPaths, String outputName) {
        try {
            Files.createDirectories(Paths.get(OUTPUT_DIR));

            // 创建临时文件列表
            String listFile = OUTPUT_DIR + "/temp_list.txt";
            try (PrintWriter writer = new PrintWriter(new FileWriter(listFile))) {
                for (String path : videoPaths) {
                    writer.println("file '" + path.replace("\\", "/") + "'");
                }
            }

            // 调用 FFmpeg 拼接
            String outputPath = OUTPUT_DIR + "/" + outputName + ".mp4";
            ProcessBuilder pb = new ProcessBuilder(
                    "ffmpeg", "-f", "concat", "-safe", "0",
                    "-i", listFile, "-c", "copy", "-y", outputPath
            );
            pb.redirectErrorStream(true);
            Process process = pb.start();

            // 等待完成
            int exitCode = process.waitFor();

            // 清理临时文件
            new File(listFile).delete();

            if (exitCode == 0 && Files.exists(Paths.get(outputPath))) {
                return outputPath;
            }
            return null;
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    /**
     * 从步骤文本中推断对应的视频片段路径：
     * 1. 先按中文关键词（颈/肩/腰/腿/呼吸）匹配文件名
     * 2. 再按 motionId + "_stepX" 或 "stepX" 这样的模式匹配文件名
     */
    private String findVideoForStep(String stepText, int index, String motionId) {
        if (stepText == null) {
            return null;
        }

        // 去掉前面的编号和多余空格，例如 "1. 坐姿脚尖点地" -> "坐姿脚尖点地"
        String cleaned = stepText.replaceAll("^[0-9\\.\\s\\u00A0]+", "");

        // 0. 先尝试用完整步骤文本在文件名中匹配
        String byFullText = findVideoByKeyword(cleaned);
        if (byFullText != null) {
            return byFullText;
        }

        // 1. 根据中文关键词匹配
        for (Map.Entry<String, String> entry : STEP_KEYWORDS.entrySet()) {
            if (cleaned.contains(entry.getKey())) {
                String byKeyword = findVideoByKeyword(entry.getValue());
                if (byKeyword != null) {
                    return byKeyword;
                }
            }
        }

        // 2. 按命名约定匹配：motionId_stepX
        if (motionId != null && !motionId.isEmpty()) {
            String pattern = motionId + "_step" + index;
            String byMotionPattern = findVideoByKeyword(pattern);
            if (byMotionPattern != null) {
                return byMotionPattern;
            }
        }

        // 3. 退化为 stepX
        String byStepIndex = findVideoByKeyword("step" + index);
        if (byStepIndex != null) {
            return byStepIndex;
        }

        // 如果都找不到，返回 null，上层会跳过这个步骤
        return null;
    }

    public String getVideoPath(String filename) {
        String path = VIDEO_DIR + "/" + filename;
        return Files.exists(Paths.get(path)) ? path : null;
    }

    private List<String> sortVideosByPreference(List<String> videos, Long userId, String bodyPart) {
        if (videos.isEmpty()) {
            return videos;
        }

        Map<String, Double> feedbackScores = loadFeedbackScores(userId);
        String normalizedBodyPart = normalizeKeyword(bodyPart);

        return videos.stream()
                .sorted((left, right) -> {
                    double rightScore = calculateVideoScore(right, feedbackScores, normalizedBodyPart);
                    double leftScore = calculateVideoScore(left, feedbackScores, normalizedBodyPart);
                    int compare = Double.compare(rightScore, leftScore);
                    if (compare != 0) {
                        return compare;
                    }
                    return left.compareToIgnoreCase(right);
                })
                .collect(Collectors.toList());
    }

    private Map<String, Double> loadFeedbackScores(Long userId) {
        LocalDateTime threshold = LocalDateTime.now().minusDays(30);
        List<Map<String, Object>> rows = jdbcTemplate.queryForList(
                "SELECT motion_name, feedback_tag, feedback_at, created_at FROM exercise_record WHERE user_id = ? AND feedback_tag IS NOT NULL AND created_at >= ?",
                userId,
                Timestamp.valueOf(threshold)
        );

        Map<String, Double> scores = new HashMap<>();
        for (Map<String, Object> row : rows) {
            String motionName = Objects.toString(row.get("motion_name"), "");
            String feedbackTag = Objects.toString(row.get("feedback_tag"), "");
            Timestamp feedbackTime = (Timestamp) row.get("feedback_at");
            Timestamp createdAt = (Timestamp) row.get("created_at");
            LocalDateTime reference = feedbackTime != null ? feedbackTime.toLocalDateTime() : createdAt.toLocalDateTime();
            long days = Math.max(java.time.Duration.between(reference, LocalDateTime.now()).toDays(), 0);
            double recency = days <= 7 ? 1.0 : days <= 14 ? 0.8 : 0.6;
            double weight = switch (feedbackTag) {
                case "fit" -> 2.5;
                case "too_easy" -> 1.4;
                case "too_hard" -> -0.8;
                case "dislike" -> -2.5;
                default -> 0.0;
            };
            String normalizedMotion = normalizeKeyword(motionName);
            if (!normalizedMotion.isEmpty() && weight != 0.0) {
                scores.merge(normalizedMotion, weight * recency, Double::sum);
            }
        }
        return scores;
    }

    private double calculateVideoScore(String videoName, Map<String, Double> feedbackScores, String normalizedBodyPart) {
        String normalizedVideo = normalizeKeyword(videoName.replaceFirst("\\.[^.]+$", ""));
        double score = 0.0;
        if (!normalizedBodyPart.isEmpty() && normalizedVideo.contains(normalizedBodyPart)) {
            score += 2.0;
        }
        for (Map.Entry<String, Double> entry : feedbackScores.entrySet()) {
            if (normalizedVideo.contains(entry.getKey()) || entry.getKey().contains(normalizedVideo)) {
                score += entry.getValue();
            }
        }
        return score;
    }

    private String normalizeKeyword(String value) {
        if (value == null) {
            return "";
        }
        return value.replaceAll("\\s+", "")
                .replaceAll("[^\\p{IsHan}A-Za-z0-9]", "")
                .toLowerCase(Locale.ROOT);
    }
}
