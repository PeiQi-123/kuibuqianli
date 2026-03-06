// 视频指导页面
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Map<String, dynamic>? motionData;

  const VideoPlayerScreen({super.key, this.motionData});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final ApiService _apiService = ApiService();
  
  List<String> _availableVideos = [];
  bool _isLoading = false;
  String? _selectedVideo;
  int _currentStep = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/video/list');
      if (response != null && response['code'] == 200) {
        setState(() {
          _availableVideos = List<String>.from(response['data'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('加载视频列表失败: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final motionName = widget.motionData?['motion_name'] ?? '微运动指导';
    final description = widget.motionData?['description'] ?? '';
    final steps = widget.motionData?['steps'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(motionName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 视频播放区域
                  Container(
                    width: double.infinity,
                    height: 220,
                    color: Colors.grey[900],
                    child: _selectedVideo != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.play_circle_outline,
                                size: 80,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedVideo!,
                                style: const TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '（实际播放需要 FFmpeg 支持）',
                                style: TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                            ],
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.video_library,
                                  size: 80,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '请选择要播放的视频',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  
                  // 视频选择
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '选择视频',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (_availableVideos.isEmpty)
                          const Text('暂无视频，请先上传视频文件')
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableVideos.map((video) {
                              final isSelected = _selectedVideo == video;
                              return ChoiceChip(
                                label: Text(video, style: const TextStyle(fontSize: 12)),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedVideo = selected ? video : null;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                  
                  // 播放控制
                  if (_selectedVideo != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: steps.isNotEmpty ? () {
                              if (_currentStep > 0) {
                                setState(() => _currentStep--);
                              }
                            } : null,
                            icon: const Icon(Icons.skip_previous, size: 36),
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() => _isPlaying = !_isPlaying);
                            },
                            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                            label: Text(_isPlaying ? '暂停' : '播放'),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            onPressed: steps.isNotEmpty ? () {
                              if (_currentStep < steps.length - 1) {
                                setState(() => _currentStep++);
                              }
                            } : null,
                            icon: const Icon(Icons.skip_next, size: 36),
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  
                  // 进度条
                  if (steps.isNotEmpty && _selectedVideo != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: LinearProgressIndicator(
                        value: (_currentStep + 1) / steps.length,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                  
                  // 视频信息
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          motionName,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        if (steps.isNotEmpty) ...[
                          Text(
                            '运动步骤 (第 ${_currentStep + 1}/${steps.length} 步)',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            color: _isPlaying ? Colors.blue[50] : Colors.grey[100],
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.blue,
                                    child: Text(
                                      '${_currentStep + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      steps[_currentStep].toString(),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            '所有步骤',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...steps.asMap().entries.map((entry) {
                            final isCompleted = entry.key < _currentStep;
                            final isCurrent = entry.key == _currentStep;
                            return Card(
                              color: isCurrent ? Colors.blue[50] : null,
                              child: ListTile(
                                leading: Icon(
                                  isCompleted ? Icons.check_circle : Icons.circle_outlined,
                                  color: isCompleted ? Colors.green : Colors.grey,
                                ),
                                title: Text(
                                  entry.value.toString(),
                                  style: TextStyle(
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                trailing: isCurrent ? const Icon(Icons.arrow_right, color: Colors.blue) : null,
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
