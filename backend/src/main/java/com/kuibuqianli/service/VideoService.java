package com.kuibuqianli.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.file.*;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class VideoService {

    @Value("${video.directory:C:/Users/lying/Desktop/kuibuqianli/backend/video}")
    private String videoDir;
    
    @Value("${video.output-directory:C:/Users/lying/Desktop/kuibuqianli/backend/video/output}")
    private String outputDir;
    
    @Value("${aliyun.video-api-url:https://dashscope.aliyuncs.com/api/v1/services/aigc/text2video/generation}")
    private String aliyunVideoApiUrl;
    
    @Value("${aliyun.api-key:sk-f2e88757a27e4355a863b94b81708917}")
    private String aliyunApiKey;
    
    private final RestTemplate restTemplate = new RestTemplate();

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

    public List<String> getAvailableVideos() {
        try {
            Files.createDirectories(Paths.get(outputDir));
            return Files.list(Paths.get(videoDir))
                    .filter(Files::isRegularFile)
                    .filter(p -> p.toString().endsWith(".mp4"))
                    .map(p -> p.getFileName().toString())
                    .collect(Collectors.toList());
        } catch (IOException e) {
            return Collections.emptyList();
        }
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
     * 为每个步骤单独查找或生成视频
     * @param steps 运动步骤列表（每个元素包含步骤名称和描述）
     * @param motionId 运动ID
     * @return 每个步骤对应的视频列表
     */
    public List<Map<String, Object>> findOrGenerateVideosForSteps(List<Map<String, Object>> steps, String motionId) {
        List<Map<String, Object>> result = new ArrayList<>();
        
        if (steps == null || steps.isEmpty()) {
            return result;
        }
        
        for (int i = 0; i < steps.size(); i++) {
            Map<String, Object> step = steps.get(i);
            String stepName = step.get("name") != null ? step.get("name").toString() : "步骤" + (i + 1);
            String instruction = step.get("instruction") != null ? step.get("instruction").toString() : "";
            String stepText = stepName + "，" + instruction;
            
            System.out.println("DEBUG: 处理步骤 " + (i + 1) + ": " + stepName);
            
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
     * 调用阿里云百炼视频生成API
     * @param description 视频描述
     * @return 生成的视频URL
     */
    private String callAliyunVideoApi(String description) {
        try {
            System.out.println("DEBUG: 调用阿里云API，描述: " + description);
            
            // 尝试多个API地址
            String[] apiUrls = {
                "https://dashscope.aliyuncs.com/api/v1/services/aigc/video-generation/video-synthesis",
                "https://dashscope-us.aliyuncs.com/api/v1/services/aigc/video-generation/video-synthesis"
            };
            
            String lastError = "";
            for (String apiUrl : apiUrls) {
                try {
                    URL url = new URL(apiUrl);
                    HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                    conn.setRequestMethod("POST");
                    conn.setRequestProperty("Content-Type", "application/json");
                    conn.setRequestProperty("Authorization", "Bearer " + aliyunApiKey);
                    conn.setRequestProperty("X-DashScope-Async", "enable");
                    conn.setConnectTimeout(30000);
                    conn.setReadTimeout(60000);
                    conn.setDoOutput(true);
                    
                    String requestBody = String.format(
                        "{\"model\": \"wan2.6-t2v\", \"input\": {\"prompt\": \"%s\"}, \"parameters\": {\"size\": \"1280*720\", \"duration\": 5}}",
                        description.replace("\"", "\\\"")
                    );
                    
                    System.out.println("DEBUG: 尝试API地址: " + apiUrl);
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
                            
                            if (responseStr.contains("task_id")) {
                                int start = responseStr.indexOf("task_id") + 10;
                                int end = responseStr.indexOf("\"", start);
                                if (end > start) {
                                    String taskId = responseStr.substring(start, end);
                                    System.out.println("DEBUG: 获取到任务ID: " + taskId);
                                    return pollVideoResult(taskId, apiUrl);
                                }
                            }
                            
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
                            lastError = errorResponse.toString();
                            System.err.println("API错误响应: " + lastError);
                        }
                    }
                } catch (Exception e) {
                    lastError = e.getMessage();
                    System.err.println("API调用失败: " + e.getMessage());
                }
            }
            
            System.err.println("所有API地址均失败，最后错误: " + lastError);
            
        } catch (Exception e) {
            System.err.println("调用阿里云视频API失败: " + e.getMessage());
            e.printStackTrace();
        }
        return null;
    }
    
    /**
     * 轮询阿里云视频生成结果
     */
    private String pollVideoResult(String taskId, String baseApiUrl) {
        try {
            // 根据baseApiUrl确定查询API地址
            String queryUrl = baseApiUrl.replace("/video-synthesis", "/query");
            URL url = new URL(queryUrl);
            int maxRetries = 180;
            int retryCount = 0;
            
            System.out.println("DEBUG: 开始轮询任务ID: " + taskId);
            System.out.println("DEBUG: 查询URL: " + queryUrl);
            
            while (retryCount < maxRetries) {
                Thread.sleep(3000);
                
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setRequestMethod("GET");
                conn.setRequestProperty("Authorization", "Bearer " + aliyunApiKey);
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
                        
                        // 解析task_status
                        String taskStatus = extractTaskStatus(responseStr);
                        System.out.println("DEBUG: 当前任务状态: " + taskStatus);
                        
                        if ("SUCCEEDED".equals(taskStatus)) {
                            // 提取视频URL - 从 results 数组中提取 url
                            String videoUrl = extractVideoUrlFromResults(responseStr);
                            if (videoUrl != null) {
                                System.out.println("DEBUG: 提取到视频URL: " + videoUrl);
                                return videoUrl;
                            }
                        } else if ("FAILED".equals(taskStatus)) {
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
}
