package com.kuibuqianli.service;

import org.springframework.stereotype.Service;
import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class VideoService {

    private static final String VIDEO_DIR = "D:/teach/kuibuqianli/kuibuqianli/video";
    private static final String OUTPUT_DIR = "D:/teach/kuibuqianli/kuibuqianli/video/output";

    public List<String> getAvailableVideos() {
        try {
            Files.createDirectories(Paths.get(OUTPUT_DIR));
            return Files.list(Paths.get(VIDEO_DIR))
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

    public String getVideoPath(String filename) {
        String path = VIDEO_DIR + "/" + filename;
        return Files.exists(Paths.get(path)) ? path : null;
    }
}
