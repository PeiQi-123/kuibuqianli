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
            
            if (bestMatchRate >= 0.30) {
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
     * 调用阿里云百炼视频生成API
     * @param description 视频描述
     * @return 生成的视频URL
     */
    private String callAliyunVideoApi(String description) {
        try {
            URL url = new URL(aliyunVideoApiUrl);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setRequestProperty("Authorization", "Bearer " + aliyunApiKey);
            conn.setDoOutput(true);
            
            String requestBody = String.format(
                "{\"model\": \"i2v-gen-2\", \"input\": {\"prompt\": \"%s\"}, \"parameters\": {\"size\": \"1280x720\", \"fps\": 24, \"duration\": 5}}",
                description.replace("\"", "\\\"")
            );
            
            try (OutputStream os = conn.getOutputStream()) {
                byte[] input = requestBody.getBytes("utf-8");
                os.write(input, 0, input.length);
            }
            
            int responseCode = conn.getResponseCode();
            if (responseCode == 200) {
                try (BufferedReader br = new BufferedReader(
                        new InputStreamReader(conn.getInputStream(), "utf-8"))) {
                    StringBuilder response = new StringBuilder();
                    String responseLine;
                    while ((responseLine = br.readLine()) != null) {
                        response.append(responseLine.trim());
                    }
                    
                    String responseStr = response.toString();
                    if (responseStr.contains("video_url")) {
                        int start = responseStr.indexOf("video_url") + 12;
                        int end = responseStr.indexOf("\"", start);
                        if (end > start) {
                            return responseStr.substring(start, end);
                        }
                    }
                    
                    if (responseStr.contains("output")) {
                        int start = responseStr.indexOf("\"url\"") > 0 ? 
                            responseStr.indexOf("\"url\"") + 7 : 
                            responseStr.indexOf("\"video\"") + 10;
                        int end = responseStr.indexOf("\"", start);
                        if (end > start) {
                            return responseStr.substring(start, end);
                        }
                    }
                }
            } else {
                System.err.println("阿里云API响应码: " + responseCode);
            }
            
        } catch (Exception e) {
            System.err.println("调用阿里云视频API失败: " + e.getMessage());
        }
        return null;
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
