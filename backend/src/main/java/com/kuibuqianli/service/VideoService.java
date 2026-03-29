package com.kuibuqianli.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.Claims;

import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.file.*;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class VideoService {

    @Value("${video.directory:C:/Users/lying/Desktop/kuibuqianli/backend/video}")
    private String videoDir;
    
    @Value("${video.output-directory:C:/Users/lying/Desktop/kuibuqianli/backend/video/output}")
    private String outputDir;
    
    @Value("${aliyun.video-api-url:https://api.klingai.com/v1/videos/generations}")
    private String aliyunVideoApiUrl;
    
    @Value("${aliyun.access-key:AEye4RGyaftyHB8adkB3KGE894ARALdt}")
    private String aliyunAccessKey;
    
    @Value("${aliyun.secret-key:PYgfRJHHfDpGtArPQPFtLEAEDyRMmtkJ}")
    private String aliyunSecretKey;
    
    @Value("${aliyun.model:kling-video-v3}")
    private String aliyunModel;
    
    private final RestTemplate restTemplate = new RestTemplate();
    
    /**
     * 生成JWT Token（可灵API认证）- 可灵官方唯一认可的正确格式
     * 关键点：
     * 1. 时间戳使用秒（不是毫秒）
     * 2. 使用setClaims()设置所有字段
     * 3. 签名方式：SignatureAlgorithm.HS256, SECRET_KEY.getBytes()
     */
    private String generateJwtToken() {
        try {
            long nowMillis = System.currentTimeMillis();
            long nowSeconds = nowMillis / 1000;
            
            System.out.println("DEBUG: 生成JWT Token（可灵官方标准格式）");
            System.out.println("  - 当前时间（毫秒）: " + nowMillis);
            System.out.println("  - 当前时间（秒）: " + nowSeconds);
            System.out.println("  - iat（签发时间）: " + nowSeconds);
            System.out.println("  - nbf（生效时间，提前60秒）: " + (nowSeconds - 60));
            System.out.println("  - exp（过期时间，1小时后）: " + (nowSeconds + 3600));
            
            // 创建claims map - 必须用这个格式
            java.util.Map<String, Object> claims = new java.util.HashMap<>();
            claims.put("iss", aliyunAccessKey);          // 必须
            claims.put("iat", nowSeconds);               // 签发时间（秒）
            claims.put("nbf", nowSeconds - 60);          // 生效时间（提前60秒）
            claims.put("exp", nowSeconds + 3600);        // 过期时间（1小时后）
            
            System.out.println("DEBUG: JWT Claims: " + claims);
            
            // 👇 可灵官方唯一认可的签名方式
            String jwtToken = Jwts.builder()
                    .setHeaderParam("alg", "HS256")      // 强制算法
                    .setHeaderParam("typ", "JWT")        // 强制类型
                    .setClaims(claims)                   // 设置所有claims
                    .signWith(
                        SignatureAlgorithm.HS256,        // 必须用这个
                        aliyunSecretKey.getBytes()       // 必须用.getBytes()
                    )
                    .compact();
            
            System.out.println("DEBUG: 生成的JWT Token长度: " + jwtToken.length());
            System.out.println("DEBUG: JWT Token（前60字符）: " + jwtToken.substring(0, Math.min(60, jwtToken.length())) + "...");
            
            // 解码验证Token结构（使用相同的签名方式）
            try {
                Claims parsedClaims = Jwts.parser()
                    .setSigningKey(aliyunSecretKey.getBytes())
                    .parseClaimsJws(jwtToken)
                    .getBody();
                
                System.out.println("DEBUG: JWT验证成功，包含字段:");
                System.out.println("  - iss: " + parsedClaims.get("iss"));
                System.out.println("  - iat: " + parsedClaims.get("iat"));
                System.out.println("  - nbf: " + parsedClaims.get("nbf"));
                System.out.println("  - exp: " + parsedClaims.get("exp"));
                
                // 验证时间格式
                Object iat = parsedClaims.get("iat");
                Object nbf = parsedClaims.get("nbf");
                Object exp = parsedClaims.get("exp");
                
                System.out.println("DEBUG: 时间格式验证:");
                System.out.println("  - iat类型: " + (iat != null ? iat.getClass().getSimpleName() : "null"));
                System.out.println("  - nbf类型: " + (nbf != null ? nbf.getClass().getSimpleName() : "null"));
                System.out.println("  - exp类型: " + (exp != null ? exp.getClass().getSimpleName() : "null"));
                
            } catch (Exception e) {
                System.err.println("DEBUG: JWT验证失败: " + e.getMessage());
                e.printStackTrace();
            }
            
            return jwtToken;
            
        } catch (Exception e) {
            System.err.println("生成JWT Token失败: " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }

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

    private static final Map<String, List<String>> BODY_PART_ALIASES = Map.ofEntries(
            Map.entry("颈部", List.of("颈", "颈椎", "脖子", "头颈")),
            Map.entry("肩部", List.of("肩", "肩颈", "斜方肌", "肩膀")),
            Map.entry("背部", List.of("背", "上背", "下背", "脊柱", "胸背")),
            Map.entry("腰部", List.of("腰", "腰背", "腰椎", "核心")),
            Map.entry("腿部", List.of("腿", "大腿", "小腿", "膝", "踝", "下肢")),
            Map.entry("手腕", List.of("手腕", "腕", "手臂", "手", "前臂"))
    );

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private record ActionCandidate(
            String actionName,
            double score,
            String category,
            List<String> reasons
    ) {
    }

    public List<String> getAvailableVideos() {
        return getAvailableVideos(null, null);
    }

    public List<String> getAvailableVideos(Long userId, String bodyPart) {
        try {
            Files.createDirectories(Paths.get(outputDir));
            List<String> videos = Files.list(Paths.get(videoDir))
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

    public List<Map<String, Object>> recommendActionCandidates(
            Long userId,
            String bodyPart,
            Map<String, Object> userInfo,
            int limit
    ) {
        List<String> availableVideos = getAvailableVideos();
        if (availableVideos.isEmpty()) {
            return Collections.emptyList();
        }

        Map<String, Double> feedbackScores = userId == null ? Collections.emptyMap() : loadFeedbackScores(userId);
        Map<String, Integer> recentUsage = userId == null ? Collections.emptyMap() : loadRecentActionUsage(userId);

        List<ActionCandidate> rankedCandidates = availableVideos.stream()
                .map(this::toActionName)
                .filter(name -> !name.isBlank())
                .distinct()
                .map(actionName -> scoreActionCandidate(actionName, bodyPart, userInfo, feedbackScores, recentUsage))
                .sorted((left, right) -> Double.compare(right.score(), left.score()))
                .toList();

        if (rankedCandidates.isEmpty()) {
            return Collections.emptyList();
        }

        return diversifyCandidates(rankedCandidates, Math.max(limit, 1)).stream()
                .limit(Math.max(limit, 1))
                .map(candidate -> {
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("action_name", candidate.actionName());
                    item.put("score", Math.round(candidate.score() * 100D) / 100D);
                    item.put("category", candidate.category());
                    item.put("reasons", candidate.reasons());
                    return item;
                })
                .collect(Collectors.toList());
    }

    public String findVideoByKeyword(String keyword) {
        try {
            return Files.list(Paths.get(videoDir))
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
     * 模糊匹配查找视频，匹配度超过30%返回视频路径
     * @param searchText 搜索文本（通常是运动步骤）
     * @return 匹配的视频路径，如果没有超过30%匹配度的视频返回null
     */
    public String fuzzyFindVideoByMatchRate(String searchText) {
        if (searchText == null || searchText.isEmpty()) {
            return null;
        }
        
        try {
            List<Path> videoFiles = Files.list(Paths.get(videoDir))
                    .filter(Files::isRegularFile)
                    .filter(p -> p.toString().endsWith(".mp4"))
                    .collect(Collectors.toList());
            
            double bestMatchRate = 0.0;
            String bestMatchPath = null;
            
            for (Path videoPath : videoFiles) {
                String fileName = videoPath.getFileName().toString();
                String videoName = fileName.replace(".mp4", "");
                
                double matchRate = calculateMatchRate(searchText, videoName);
                
                if (matchRate > bestMatchRate) {
                    bestMatchRate = matchRate;
                    bestMatchPath = videoPath.toString();
                }
            }
            
            if (bestMatchRate >= 0.40) {
                return bestMatchPath;
            }
            return null;
            
        } catch (IOException e) {
            return null;
        }
    }
    
    /**
     * 计算两个字符串的匹配度（基于字符重叠）
     * @param text1 文本1
     * @param text2 文本2
     * @return 匹配度（0-1之间）
     */
    private double calculateMatchRate(String text1, String text2) {
        if (text1 == null || text2 == null) {
            return 0.0;
        }
        
        Set<Character> chars1 = new HashSet<>();
        Set<Character> chars2 = new HashSet<>();
        
        for (char c : text1.toCharArray()) {
            if (Character.isLetterOrDigit(c) || isChinese(c)) {
                chars1.add(c);
            }
        }
        
        for (char c : text2.toCharArray()) {
            if (Character.isLetterOrDigit(c) || isChinese(c)) {
                chars2.add(c);
            }
        }
        
        if (chars1.isEmpty() || chars2.isEmpty()) {
            return 0.0;
        }
        
        Set<Character> intersection = new HashSet<>(chars1);
        intersection.retainAll(chars2);
        
        int smallerSize = Math.min(chars1.size(), chars2.size());
        return (double) intersection.size() / smallerSize;
    }
    
    private boolean isChinese(char c) {
        return '\u4e00' <= c && c <= '\u9fff';
    }

    /**
     * 根据运动步骤生成或查找视频
     * @param steps 运动步骤列表
     * @param motionId 运动ID
     * @return 视频路径
     */
    public String findOrGenerateVideo(List<String> steps, String motionId) {
        if (steps == null || steps.isEmpty()) {
            return null;
        }
        
        String combinedText = String.join(" ", steps);
        
        String existingVideo = fuzzyFindVideoByMatchRate(combinedText);
        if (existingVideo != null) {
            return existingVideo;
        }
        
        return generateVideoFromSteps(steps, motionId);
    }
    
    /**
     * Find or generate videos for steps
     * @param steps Step list, each step contains name and instruction
     * @param motionId Motion ID
     * @return Video list for each step
     */
    public List<Map<String, Object>> findOrGenerateVideosForSteps(List<Map<String, Object>> steps, String motionId) {
        List<Map<String, Object>> result = new ArrayList<>();
        
        if (steps == null || steps.isEmpty()) {
            return result;
        }
        
        for (int i = 0; i < steps.size(); i++) {
            Map<String, Object> step = steps.get(i);
            String stepName = step.get("name") != null ? step.get("name").toString() : "Step" + (i + 1);
            String instruction = step.get("instruction") != null ? step.get("instruction").toString() : "";
            String stepText = stepName + ", " + instruction;
            
            System.out.println("DEBUG: Process step " + (i + 1) + ": " + stepName);
            
            String videoPath = findOrGenerateVideoForSingleStep(stepText, stepName);
            
            Map<String, Object> stepVideo = new HashMap<>();
            stepVideo.put("stepIndex", i + 1);
            stepVideo.put("stepName", stepName);
            stepVideo.put("videoPath", videoPath);
            stepVideo.put("videoFileName", videoPath != null ? extractFileName(videoPath) : null);
            
            result.add(stepVideo);
        }
        
        return result;
    }
    
    /**
     * Find local videos for steps (no generation)
     * @param steps Step list, each step contains name and instruction
     * @param motionId Motion ID
     * @return Video list for each step
     */
    public List<Map<String, Object>> findVideosForSteps(List<Map<String, Object>> steps, String motionId) {
        List<Map<String, Object>> result = new ArrayList<>();
        
        if (steps == null || steps.isEmpty()) {
            return result;
        }
        
        for (int i = 0; i < steps.size(); i++) {
            Map<String, Object> step = steps.get(i);
            String stepName = step.get("name") != null ? step.get("name").toString() : "Step" + (i + 1);
            String instruction = step.get("instruction") != null ? step.get("instruction").toString() : "";
            String stepText = stepName + ", " + instruction;
            
            System.out.println("DEBUG: Find video for step " + (i + 1) + ": " + stepName);
            
            String videoPath = fuzzyFindVideoByMatchRate(stepText);
            
            Map<String, Object> stepVideo = new HashMap<>();
            stepVideo.put("stepIndex", i + 1);
            stepVideo.put("stepName", stepName);
            stepVideo.put("videoPath", videoPath);
            stepVideo.put("videoFileName", videoPath != null ? extractFileName(videoPath) : null);
            stepVideo.put("found", videoPath != null);
            
            result.add(stepVideo);
        }
        
        return result;
    }
    
    /**
     * Generate videos for steps
     * @param steps Step list, each step contains name and instruction
     * @param motionId Motion ID
     * @return Video list for each step
     */
    public List<Map<String, Object>> generateVideosForSteps(List<Map<String, Object>> steps, String motionId) {
        List<Map<String, Object>> result = new ArrayList<>();
        
        if (steps == null || steps.isEmpty()) {
            return result;
        }
        
        for (int i = 0; i < steps.size(); i++) {
            Map<String, Object> step = steps.get(i);
            String stepName = step.get("name") != null ? step.get("name").toString() : "Step" + (i + 1);
            String instruction = step.get("instruction") != null ? step.get("instruction").toString() : "";
            String stepText = stepName + ", " + instruction;
            
            System.out.println("DEBUG: Generate video for step " + (i + 1) + ": " + stepName);
            
            String videoPath = generateVideoFromSingleStep(stepText, stepName);
            
            Map<String, Object> stepVideo = new HashMap<>();
            stepVideo.put("stepIndex", i + 1);
            stepVideo.put("stepName", stepName);
            stepVideo.put("videoPath", videoPath);
            stepVideo.put("videoFileName", videoPath != null ? extractFileName(videoPath) : null);
            stepVideo.put("generated", videoPath != null);
            
            result.add(stepVideo);
        }
        
        return result;
    }
    
    /**
     * 从路径中提取文件名
     */
    private String extractFileName(String path) {
        if (path == null) return null;
        int lastSlash = Math.max(path.lastIndexOf('/'), path.lastIndexOf('\\'));
        return lastSlash >= 0 ? path.substring(lastSlash + 1) : path;
    }
    
    /**
     * 为单个步骤查找或生成视频
     */
    private String findOrGenerateVideoForSingleStep(String stepText, String stepId) {
        String existingVideo = fuzzyFindVideoByMatchRate(stepText);
        if (existingVideo != null) {
            System.out.println("DEBUG: 步骤 " + stepId + " 找到匹配视频: " + existingVideo);
            return existingVideo;
        }
        
        System.out.println("DEBUG: 步骤 " + stepId + " 未找到匹配视频，调用API生成...");
        return generateVideoFromSingleStep(stepText, stepId);
    }
    
    /**
     * 调用阿里云百炼API生成视频
     * @param steps 运动步骤
     * @param motionId 运动ID
     * @return 生成的视频路径
     */
    public String generateVideoFromSteps(List<String> steps, String motionId) {
        try {
            String videoDescription = String.join("；", steps);
            
            String videoUrl = callAliyunVideoApi(videoDescription);
            
            if (videoUrl != null && !videoUrl.isEmpty()) {
                String fileName = motionId + "_" + System.currentTimeMillis() + ".mp4";
                String savePath = videoDir + "/" + fileName;
                
                boolean saved = downloadVideo(videoUrl, savePath);
                if (saved) {
                    return savePath;
                }
            }
            
            String concatenatedPath = concatenateVideosBySteps(steps, motionId);
            if (concatenatedPath != null) {
                return concatenatedPath;
            }
            
            return findVideoForStep(String.join(" ", steps), 1, motionId);
            
        } catch (Exception e) {
            System.err.println("视频生成失败: " + e.getMessage());
            e.printStackTrace();
            
            String concatenatedPath = concatenateVideosBySteps(steps, motionId);
            if (concatenatedPath != null) {
                return concatenatedPath;
            }
            
            return findVideoForStep(String.join(" ", steps), 1, motionId);
        }
    }
    
    /**
     * 为单个步骤调用阿里云API生成视频
     * @param stepText 步骤文本（包含名称和描述）
     * @param stepName 步骤名称（用于视频文件名）
     */
    private String generateVideoFromSingleStep(String stepText, String stepName) {
        try {
            System.out.println("DEBUG: 为步骤生成视频: " + stepName);
            
            String videoUrl = callAliyunVideoApi(stepText);
            
            if (videoUrl != null && !videoUrl.isEmpty()) {
                String fileName = stepName + ".mp4";
                String savePath = videoDir + "/" + fileName;
                
                System.out.println("DEBUG: 下载视频到: " + savePath);
                
                boolean saved = downloadVideo(videoUrl, savePath);
                if (saved) {
                    System.out.println("DEBUG: 步骤 " + stepName + " 视频生成并保存成功");
                    return savePath;
                }
            }
            
            System.out.println("DEBUG: 步骤 " + stepName + " 视频生成失败，返回null");
            return null;
            
        } catch (Exception e) {
            System.err.println("步骤 " + stepName + " 视频生成失败: " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }
    
    /**
     * 调用可灵API生成视频
     * @param description 视频描述
     * @return 视频URL或null
     */
    private String callAliyunVideoApi(String description) {
        try {
            System.out.println("DEBUG: 调用可灵API，描述: " + description);
            
            // 检查API密钥是否已配置
            if (aliyunAccessKey == null || aliyunAccessKey.isEmpty() || 
                aliyunSecretKey == null || aliyunSecretKey.isEmpty()) {
                System.err.println("ERROR: 可灵API密钥未配置");
                System.err.println("ERROR: Access Key: " + (aliyunAccessKey != null ? "已设置" : "未设置"));
                System.err.println("ERROR: Secret Key: " + (aliyunSecretKey != null ? "已设置" : "未设置"));
                return null;
            }
            
            // 生成JWT Token
            String jwtToken = generateJwtToken();
            if (jwtToken == null) {
                System.err.println("ERROR: 生成JWT Token失败");
                return null;
            }
            
            System.out.println("DEBUG: 生成的JWT Token长度: " + jwtToken.length());
            System.out.println("DEBUG: JWT Token前50字符: " + jwtToken.substring(0, Math.min(50, jwtToken.length())) + "...");
            System.out.println("DEBUG: JWT Token后50字符: ..." + jwtToken.substring(Math.max(0, jwtToken.length() - 50)));
            
            // 可灵视频生成API地址
            String apiUrl = aliyunVideoApiUrl;
            
            URL url = new URL(apiUrl);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setRequestProperty("Authorization", "Bearer " + jwtToken);
            conn.setConnectTimeout(30000);
            conn.setReadTimeout(60000);
            conn.setDoOutput(true);
            
            // 可灵API请求体格式（根据官方文档）
            String requestBody = String.format(
                "{\"model\": \"%s\", \"prompt\": \"%s\", \"duration\": 5, \"ratio\": \"16:9\", \"mode\": \"std\"}",
                aliyunModel,
                description.replace("\"", "\\\"")
            );
            
            System.out.println("DEBUG: API地址: " + apiUrl);
            System.out.println("DEBUG: 请求体: " + requestBody);
            
            try (OutputStream os = conn.getOutputStream()) {
                byte[] input = requestBody.getBytes("utf-8");
                os.write(input, 0, input.length);
            }
            
            int responseCode = conn.getResponseCode();
            System.out.println("DEBUG: API响应码: " + responseCode);
            
            if (responseCode == 200 || responseCode == 201) {
                try (BufferedReader br = new BufferedReader(
                        new InputStreamReader(conn.getInputStream(), "utf-8"))) {
                    StringBuilder response = new StringBuilder();
                    String responseLine;
                    while ((responseLine = br.readLine()) != null) {
                        response.append(responseLine.trim());
                    }
                    
                    String responseStr = response.toString();
                    System.out.println("DEBUG: API响应: " + responseStr);
                    
                    // 解析响应，获取task_id
                    if (responseStr.contains("task_id")) {
                        // 简单解析JSON，获取task_id
                        int start = responseStr.indexOf("task_id") + 10;
                        int end = responseStr.indexOf("\"", start);
                        if (end > start) {
                            String taskId = responseStr.substring(start, end);
                            System.out.println("DEBUG: 获取到任务ID: " + taskId);
                            return pollVideoResult(taskId, jwtToken);
                        }
                    }
                    
                    // 如果直接返回视频URL
                    if (responseStr.contains("video_url")) {
                        int start = responseStr.indexOf("video_url") + 12;
                        int end = responseStr.indexOf("\"", start);
                        if (end > start) {
                            return responseStr.substring(start, end);
                        }
                    }
                }
            } else {
                try (BufferedReader br = new BufferedReader(
                        new InputStreamReader(conn.getErrorStream(), "utf-8"))) {
                    StringBuilder errorResponse = new StringBuilder();
                    String responseLine;
                    while ((responseLine = br.readLine()) != null) {
                        errorResponse.append(responseLine.trim());
                    }
                    String errorStr = errorResponse.toString();
                    System.err.println("API错误响应: " + errorStr);
                }
            }
            
        } catch (Exception e) {
            System.err.println("调用可灵视频API失败: " + e.getMessage());
            e.printStackTrace();
        }
        return null;
    }
    
    /**
     * 轮询可灵视频生成结果
     */
    private String pollVideoResult(String taskId, String jwtToken) {
        try {
            // 可灵API查询地址
            String queryUrl = "https://api.klingai.com/v1/videos/tasks/" + taskId;
            URL url = new URL(queryUrl);
            int maxRetries = 60; // 最多尝试60次（3分钟）
            int retryCount = 0;
            
            System.out.println("DEBUG: 开始轮询任务ID: " + taskId);
            System.out.println("DEBUG: 查询URL: " + queryUrl);
            
            while (retryCount < maxRetries) {
                Thread.sleep(3000); // 每3秒查询一次
                
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setRequestMethod("GET");
                conn.setRequestProperty("Authorization", "Bearer " + jwtToken);
                conn.setConnectTimeout(10000);
                conn.setReadTimeout(30000);
                
                int responseCode = conn.getResponseCode();
                System.out.println("DEBUG: 查询响应码: " + responseCode);
                
                if (responseCode == 200) {
                    try (BufferedReader br = new BufferedReader(
                            new InputStreamReader(conn.getInputStream(), "utf-8"))) {
                        StringBuilder response = new StringBuilder();
                        String responseLine;
                        while ((responseLine = br.readLine()) != null) {
                            response.append(responseLine.trim());
                        }
                        
                        String responseStr = response.toString();
                        System.out.println("DEBUG: 轮询响应: " + responseStr);
                        
                        // 解析可灵API的状态字段
                        String taskStatus = extractKlingTaskStatus(responseStr);
                        System.out.println("DEBUG: 当前任务状态: " + taskStatus);
                        
                        if ("succeeded".equalsIgnoreCase(taskStatus) || "completed".equalsIgnoreCase(taskStatus)) {
                            // 提取视频URL
                            String videoUrl = extractKlingVideoUrl(responseStr);
                            if (videoUrl != null) {
                                System.out.println("DEBUG: 提取到视频URL: " + videoUrl);
                                return videoUrl;
                            }
                        } else if ("failed".equalsIgnoreCase(taskStatus) || "error".equalsIgnoreCase(taskStatus)) {
                            System.err.println("视频生成任务失败");
                            return null;
                        }
                    }
                } else {
                    System.err.println("查询API返回错误码: " + responseCode);
                    try (BufferedReader br = new BufferedReader(
                            new InputStreamReader(conn.getErrorStream(), "utf-8"))) {
                        StringBuilder errorResponse = new StringBuilder();
                        String responseLine;
                        while ((responseLine = br.readLine()) != null) {
                            errorResponse.append(responseLine.trim());
                        }
                        System.err.println("错误详情: " + errorResponse.toString());
                    }
                }
                
                retryCount++;
                System.out.println("DEBUG: 等待视频生成... (" + retryCount + "/" + maxRetries + ")");
            }
        } catch (Exception e) {
            System.err.println("轮询视频结果失败: " + e.getMessage());
            e.printStackTrace();
        }
        return null;
    }
    
    private String extractVideoUrlFromResults(String response) {
        if (response == null) return null;
        try {
            // 查找 results 数组中的 url 字段
            int resultsIdx = response.indexOf("results");
            if (resultsIdx >= 0) {
                int urlIdx = response.indexOf("\"url\"", resultsIdx);
                if (urlIdx >= 0) {
                    int start = urlIdx + 7;
                    int end = response.indexOf("\"", start);
                    if (end > start) {
                        return response.substring(start, end);
                    }
                }
            }
            // 备选：直接查找 video_url
            if (response.contains("video_url")) {
                int start = response.indexOf("video_url") + 12;
                int end = response.indexOf("\"", start);
                if (end > start) {
                    return response.substring(start, end);
                }
            }
        } catch (Exception e) {
            System.err.println("提取video_url失败: " + e.getMessage());
        }
        return null;
    }
    
    private String extractTaskStatus(String response) {
        if (response == null) return "UNKNOWN";
        try {
            int idx = response.indexOf("task_status");
            if (idx >= 0) {
                int start = response.indexOf("\"", idx) + 1;
                int end = response.indexOf("\"", start);
                if (end > start) {
                    return response.substring(start, end);
                }
            }
        } catch (Exception e) {
            System.err.println("解析task_status失败: " + e.getMessage());
        }
        return "UNKNOWN";
    }
    
    /**
     * 提取可灵API视频URL
     */
    private String extractKlingVideoUrl(String response) {
        if (response == null) return null;
        try {
            // 尝试多种可能的字段名
            String[] urlFields = {"video_url", "url", "result_url", "output_url"};
            for (String field : urlFields) {
                int idx = response.indexOf(field);
                if (idx >= 0) {
                    int start = response.indexOf("\"", idx + field.length()) + 1;
                    int end = response.indexOf("\"", start);
                    if (end > start) {
                        return response.substring(start, end);
                    }
                }
            }
            
            // 如果没有找到标准字段，尝试从data或result中提取
            if (response.contains("http") && response.contains("mp4")) {
                int httpStart = response.indexOf("http");
                int mp4End = response.indexOf("mp4", httpStart);
                if (mp4End > httpStart) {
                    return response.substring(httpStart, mp4End + 3);
                }
            }
        } catch (Exception e) {
            System.err.println("解析可灵视频URL失败: " + e.getMessage());
        }
        return null;
    }
    
    /**
     * 提取可灵API任务状态
     */
    private String extractKlingTaskStatus(String response) {
        if (response == null) return "UNKNOWN";
        try {
            // 尝试多种可能的状态字段名
            String[] statusFields = {"status", "task_status", "state"};
            for (String field : statusFields) {
                int idx = response.indexOf(field);
                if (idx >= 0) {
                    int start = response.indexOf("\"", idx + field.length()) + 1;
                    int end = response.indexOf("\"", start);
                    if (end > start) {
                        return response.substring(start, end);
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("解析可灵任务状态失败: " + e.getMessage());
        }
        return "UNKNOWN";
    }
    
    /**
     * 下载视频到本地
     * @param videoUrl 视频URL
     * @param savePath 保存路径
     * @return 是否成功
     */
    private boolean downloadVideo(String videoUrl, String savePath) {
        try {
            URL url = new URL(videoUrl);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            
            try (InputStream in = conn.getInputStream();
                 FileOutputStream out = new FileOutputStream(savePath)) {
                byte[] buffer = new byte[4096];
                int bytesRead;
                while ((bytesRead = in.read(buffer)) != -1) {
                    out.write(buffer, 0, bytesRead);
                }
            }
            
            return Files.exists(Paths.get(savePath));
        } catch (Exception e) {
            System.err.println("下载视频失败: " + e.getMessage());
            return false;
        }
    }

    /**
     * 根据关键词列表拼接视频（保留原有逻辑，方便直接按文件名关键字调用）
     */
    public String concatenateVideos(List<String> videoKeywords, String outputName) {
        try {
            Files.createDirectories(Paths.get(outputDir));
            
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
            Files.createDirectories(Paths.get(outputDir));

            // 创建临时文件列表
            String listFile = outputDir + "/temp_list.txt";
            try (PrintWriter writer = new PrintWriter(new FileWriter(listFile))) {
                for (String path : videoPaths) {
                    writer.println("file '" + path.replace("\\", "/") + "'");
                }
            }

            // 调用 FFmpeg 拼接
            String outputPath = outputDir + "/" + outputName + ".mp4";
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
        System.out.println("DEBUG getVideoPath: videoDir=" + videoDir + ", filename=" + filename);
        Path path = Paths.get(videoDir, filename);
        System.out.println("DEBUG full path: " + path);
        System.out.println("DEBUG file exists: " + Files.exists(path));
        return Files.exists(path) ? path.toString() : null;
    }

    private String toActionName(String filename) {
        if (filename == null) {
            return "";
        }
        return filename.replaceFirst("\\.[^.]+$", "")
                .replace('_', ' ')
                .replace('-', ' ')
                .trim();
    }

    private ActionCandidate scoreActionCandidate(
            String actionName,
            String bodyPart,
            Map<String, Object> userInfo,
            Map<String, Double> feedbackScores,
            Map<String, Integer> recentUsage
    ) {
        double score = 1.0D;
        List<String> reasons = new ArrayList<>();
        String normalizedAction = normalizeKeyword(actionName);
        String category = inferActionCategory(actionName);

        if (matchesBodyPart(actionName, bodyPart)) {
            score += 3.0D;
            reasons.add("目标部位命中");
        }

        List<String> preferredBodyParts = extractStringList(userInfo == null ? null : userInfo.get("preferred_body_parts"));
        if (!preferredBodyParts.isEmpty() && preferredBodyParts.stream().anyMatch(part -> matchesBodyPart(actionName, part))) {
            score += 2.0D;
            reasons.add("贴近历史偏好部位");
        }

        List<String> preferredSportTypes = extractStringList(userInfo == null ? null : userInfo.get("preferred_sport_types"));
        if (!preferredSportTypes.isEmpty() && preferredSportTypes.stream().anyMatch(type -> matchesPreference(actionName, type))) {
            score += 1.8D;
            reasons.add("贴近历史偏好类型");
        }

        List<String> preferredDifficulty = extractStringList(userInfo == null ? null : userInfo.get("preferred_difficulty"));
        if (!preferredDifficulty.isEmpty()) {
            String difficulty = preferredDifficulty.get(0);
            if ((difficulty.contains("零基础") || difficulty.contains("入门"))
                    && containsAnyNormalized(normalizedAction, "拉伸", "放松", "呼吸", "按摩")) {
                score += 0.9D;
                reasons.add("适合低难度偏好");
            } else if ((difficulty.contains("有难度") || difficulty.contains("进阶"))
                    && containsAnyNormalized(normalizedAction, "动态", "力量", "提踵", "旋转", "绕环")) {
                score += 0.9D;
                reasons.add("适合进阶偏好");
            }
        }

        List<String> specialCases = extractStringList(userInfo == null ? null : userInfo.get("explicit_special_cases"));
        if (!specialCases.isEmpty()) {
            if (containsAnyNormalized(normalizedAction, "力量", "深蹲", "高抬腿", "动态")) {
                score -= 0.8D;
                reasons.add("存在特殊情况，降低高刺激动作权重");
            }
            if (containsAnyNormalized(normalizedAction, "拉伸", "放松", "呼吸", "按摩")) {
                score += 0.6D;
                reasons.add("存在特殊情况，提升舒缓动作权重");
            }
        }

        double feedbackScore = feedbackScores.entrySet().stream()
                .filter(entry -> normalizedAction.contains(entry.getKey()) || entry.getKey().contains(normalizedAction))
                .mapToDouble(Map.Entry::getValue)
                .sum();
        if (feedbackScore != 0.0D) {
            score += feedbackScore;
            reasons.add(feedbackScore > 0 ? "近期正反馈较好" : "近期负反馈较多");
        }

        int usageCount = recentUsage.entrySet().stream()
                .filter(entry -> normalizedAction.contains(entry.getKey()) || entry.getKey().contains(normalizedAction))
                .mapToInt(Map.Entry::getValue)
                .sum();
        if (usageCount > 0) {
            double fatiguePenalty = Math.min(usageCount * 0.7D, 2.1D);
            score -= fatiguePenalty;
            reasons.add("近期重复较多，触发疲劳降权");
        } else {
            score += 0.35D;
            reasons.add("近期较少出现，增加新鲜度");
        }

        return new ActionCandidate(actionName, score, category, reasons);
    }

    private List<ActionCandidate> diversifyCandidates(List<ActionCandidate> rankedCandidates, int limit) {
        List<ActionCandidate> selected = new ArrayList<>();
        Set<String> selectedNames = new HashSet<>();
        Set<String> usedCategories = new HashSet<>();

        for (ActionCandidate candidate : rankedCandidates) {
            if (selected.size() >= limit) {
                break;
            }
            if (selectedNames.contains(candidate.actionName())) {
                continue;
            }
            if (!candidate.category().isBlank() && usedCategories.contains(candidate.category())) {
                continue;
            }
            selected.add(candidate);
            selectedNames.add(candidate.actionName());
            if (!candidate.category().isBlank()) {
                usedCategories.add(candidate.category());
            }
        }

        for (ActionCandidate candidate : rankedCandidates) {
            if (selected.size() >= limit) {
                break;
            }
            if (selectedNames.contains(candidate.actionName())) {
                continue;
            }
            selected.add(candidate);
            selectedNames.add(candidate.actionName());
        }

        return selected;
    }

    private Map<String, Integer> loadRecentActionUsage(Long userId) {
        LocalDateTime threshold = LocalDateTime.now().minusDays(3);
        List<Map<String, Object>> rows = jdbcTemplate.queryForList(
                "SELECT motion_name, COUNT(*) AS usage_count FROM exercise_record WHERE user_id = ? AND created_at >= ? GROUP BY motion_name",
                userId,
                Timestamp.valueOf(threshold)
        );

        Map<String, Integer> result = new HashMap<>();
        for (Map<String, Object> row : rows) {
            String motionName = normalizeKeyword(Objects.toString(row.get("motion_name"), ""));
            Object usageValue = row.get("usage_count");
            int usageCount = usageValue instanceof Number ? ((Number) usageValue).intValue() : 0;
            if (!motionName.isEmpty() && usageCount > 0) {
                result.put(motionName, usageCount);
            }
        }
        return result;
    }

    private String inferActionCategory(String actionName) {
        String normalizedAction = normalizeKeyword(actionName);
        if (containsAnyNormalized(normalizedAction, "呼吸")) {
            return "深呼吸";
        }
        if (containsAnyNormalized(normalizedAction, "按摩", "按压", "放松")) {
            return "按摩放松";
        }
        if (containsAnyNormalized(normalizedAction, "力量", "提踵", "抬腿", "深蹲")) {
            return "微力量锻炼";
        }
        if (containsAnyNormalized(normalizedAction, "绕环", "旋转", "活动")) {
            return "关节活动";
        }
        if (containsAnyNormalized(normalizedAction, "动态", "摆")) {
            return "动态拉伸";
        }
        if (containsAnyNormalized(normalizedAction, "拉伸", "伸展")) {
            return "静态拉伸";
        }
        return "";
    }

    private boolean matchesBodyPart(String actionName, String bodyPart) {
        if (bodyPart == null || bodyPart.isBlank()) {
            return false;
        }
        String normalizedAction = normalizeKeyword(actionName);
        for (String keyword : resolveBodyPartKeywords(normalizeKeyword(bodyPart))) {
            if (normalizedAction.contains(keyword)) {
                return true;
            }
        }
        return false;
    }

    private boolean matchesPreference(String actionName, String preference) {
        if (preference == null || preference.isBlank()) {
            return false;
        }
        String normalizedAction = normalizeKeyword(actionName);
        String normalizedPreference = normalizeKeyword(preference);
        if (normalizedAction.contains(normalizedPreference) || normalizedPreference.contains(normalizedAction)) {
            return true;
        }
        return switch (preference) {
            case "静态拉伸" -> containsAnyNormalized(normalizedAction, "拉伸", "伸展");
            case "动态拉伸" -> containsAnyNormalized(normalizedAction, "动态", "摆");
            case "关节活动" -> containsAnyNormalized(normalizedAction, "绕环", "旋转", "活动");
            case "按摩放松" -> containsAnyNormalized(normalizedAction, "按摩", "按压", "放松");
            case "体态矫正" -> containsAnyNormalized(normalizedAction, "体态", "收下巴", "矫正");
            case "深呼吸" -> containsAnyNormalized(normalizedAction, "呼吸");
            case "眼部放松" -> containsAnyNormalized(normalizedAction, "眼");
            case "微力量锻炼" -> containsAnyNormalized(normalizedAction, "力量", "提踵", "抬腿", "深蹲");
            default -> false;
        };
    }

    private List<String> extractStringList(Object value) {
        if (!(value instanceof List<?> list)) {
            return Collections.emptyList();
        }
        return list.stream()
                .map(String::valueOf)
                .filter(item -> !item.isBlank())
                .toList();
    }

    private boolean containsAnyNormalized(String source, String... keywords) {
        for (String keyword : keywords) {
            if (source.contains(normalizeKeyword(keyword))) {
                return true;
            }
        }
        return false;
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
        for (String keyword : resolveBodyPartKeywords(normalizedBodyPart)) {
            if (normalizedVideo.contains(keyword)) {
                score += keyword.length() >= 2 ? 2.0 : 1.2;
            }
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

    private List<String> resolveBodyPartKeywords(String normalizedBodyPart) {
        if (normalizedBodyPart == null || normalizedBodyPart.isEmpty()) {
            return Collections.emptyList();
        }

        LinkedHashSet<String> keywords = new LinkedHashSet<>();
        keywords.add(normalizedBodyPart);

        String bodyPartWithoutSuffix = normalizedBodyPart.endsWith("部")
                ? normalizedBodyPart.substring(0, normalizedBodyPart.length() - 1)
                : normalizedBodyPart;
        if (!bodyPartWithoutSuffix.isEmpty()) {
            keywords.add(bodyPartWithoutSuffix);
        }

        List<String> aliases = BODY_PART_ALIASES.get(normalizedBodyPart);
        if (aliases != null) {
            for (String alias : aliases) {
                String normalizedAlias = normalizeKeyword(alias);
                if (!normalizedAlias.isEmpty()) {
                    keywords.add(normalizedAlias);
                }
            }
        }

        return new ArrayList<>(keywords);
    }
}
