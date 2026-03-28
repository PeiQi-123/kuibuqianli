// 视频指导页面
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../services/api_service.dart';
import '../services/sedentary_reminder_service.dart';
import '../services/storage_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Map<String, dynamic>? motionData;

  const VideoPlayerScreen({super.key, this.motionData});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final ApiService _apiService = ApiService();
  
  List<String> _matchedVideos = [];
  bool _isLoading = false;
  String? _selectedVideo;
  int _currentStep = 0;
  bool _isPlaying = false;
  bool _isSavingRecord = false;
  bool _recordSaved = false;
  int? _savedRecordId;
  bool _isSavingFeedback = false;
  String? _feedbackTag;
  String? _feedbackLearningMessage;
  bool _isRefreshingInsights = false;
  Map<String, dynamic>? _latestLearningInsights;

  Map<String, dynamic>? get _preferenceApplied => widget.motionData?['preference_applied'] as Map<String, dynamic>?;

  VideoPlayerController? _controller;
  bool _isControllerInitialized = false;
  bool _isAdvancingVideo = false;

  bool get _supportsEmbeddedVideo {
    // media_kit支持所有平台，但暂时先用url_launcher方案
    return false;
  }

  @override
  void initState() {
    super.initState();
    _generateOrLoadVideos();
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleVideoProgress);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _generateOrLoadVideos() async {
    setState(() => _isLoading = true);
    
    final actions = (widget.motionData?['actions'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final motionId = widget.motionData?['motion_id']?.toString() ?? 'motion';
    
    if (actions.isNotEmpty) {
      try {
        final response = await _apiService.post('/video/find-or-generate-steps', {
          'steps': actions,
          'motionId': motionId,
        });
        
        if (response != null && response['code'] == 200) {
          final stepVideos = response['data'] as List<dynamic>? ?? [];
          if (stepVideos.isNotEmpty) {
            final validVideos = stepVideos
                .where((v) => v['videoFileName'] != null && v['videoFileName'].toString().isNotEmpty)
                .map((v) => v['videoFileName'].toString())
                .toList();
            
            if (validVideos.isNotEmpty) {
              setState(() {
                _matchedVideos = validVideos;
                _selectedVideo = validVideos.first;
                _currentStep = 0;
              });
              setState(() => _isLoading = false);
              return;
            }
          }
        }
      } catch (e) {
        debugPrint('生成/查找视频失败: $e');
      }
    }
    
    await _loadVideos();
  }

  Future<void> _openVideo() async {
    if (_selectedVideo == null) return;

    try {
      setState(() => _isLoading = true);
      
      final response = await _apiService.post(
        '/video/play',
        {'filename': _selectedVideo},
      );
      
      if (response != null && response['code'] == 200) {
        final videoUrl = response['data']?['url'];
        if (videoUrl != null) {
          final url = Uri.parse('${ApiService.baseUrl}$videoUrl');
          debugPrint('播放URL: $url');
          
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.platformDefault);
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('无法打开视频播放器')),
            );
          }
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response?['message'] ?? '获取视频失败')),
        );
      }
    } catch (e) {
      debugPrint('获取视频URL失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法播放视频: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    try {
      final userId = await StorageService.getUserId();
      final params = <String, String>{};
      if (userId != null && userId.isNotEmpty) {
        params['userId'] = userId;
      }
      final bodyPart = widget.motionData?['body_part']?.toString();
      if (bodyPart != null && bodyPart.isNotEmpty) {
        params['bodyPart'] = bodyPart;
      }

      final response = await _apiService.get(
        '/video/list',
        params: params.isEmpty ? null : params,
      );
      if (response != null && response['code'] == 200) {
        final videos = List<String>.from(response['data'] ?? []);
        final matchedVideos = _matchVideosToActions(videos);
        setState(() {
          _matchedVideos = matchedVideos;
          _selectedVideo = matchedVideos.isNotEmpty ? matchedVideos.first : null;
          _currentStep = 0;
        });
        if (_selectedVideo != null) {
          await _initVideoController(autoPlay: true);
        }
      }
    } catch (e) {
      debugPrint('加载视频列表失败: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveExerciseRecord() async {
    if (_isSavingRecord || _recordSaved) return;

    final userId = await StorageService.getUserId();
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未获取到当前用户，无法保存运动记录')),
      );
      return;
    }

    setState(() => _isSavingRecord = true);

    try {
      final response = await _apiService.post('/motion/record?userId=$userId', {
        'motionId': widget.motionData?['motion_id'] ?? widget.motionData?['motion_name'] ?? 'custom_motion',
        'motionName': widget.motionData?['motion_name'] ?? '微运动训练',
        'duration': _estimatedDurationSeconds(),
        'completed': true,
        'recommendationSummary': _preferenceApplied?['summary'],
        'recommendationMatchedItems': _preferenceMatchedItems(),
        'recommendationTrace': widget.motionData?['recommendation_trace'] ?? const [],
      });

      if (!mounted) return;
      if (response != null && response['code'] == 200) {
        final data = response['data'] as Map<String, dynamic>?;
        _savedRecordId = data?['recordId'] as int?;
        await SedentaryReminderService.instance.markExerciseCompleted();
        if (!mounted) return;
        setState(() {
          _recordSaved = true;
          _isSavingRecord = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已记录到健康数据')), 
        );
        await _showFeedbackDialog();
      } else {
        setState(() => _isSavingRecord = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response?['message']?.toString() ?? '保存运动记录失败')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingRecord = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存运动记录失败: $e')),
      );
    }
  }

  Future<void> _showFeedbackDialog() async {
    if (_savedRecordId == null || !mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('本次推荐是否合适？'),
          content: const Text('你的反馈会参与后续偏好学习，让下次推荐更贴近你的需求。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('稍后再说'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('too_easy'),
              child: const Text('太简单'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('fit'),
              child: const Text('合适'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('too_hard'),
              child: const Text('太难'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('dislike'),
              child: const Text('不喜欢'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await _submitFeedback(result);
    }
  }

  Future<void> _submitFeedback(String tag) async {
    if (_savedRecordId == null || _isSavingFeedback) return;
    final userId = await StorageService.getUserId();
    if (userId == null || userId.isEmpty) return;

    setState(() => _isSavingFeedback = true);
    try {
      final response = await _apiService.post('/motion/feedback?userId=$userId', {
        'recordId': _savedRecordId,
        'feedbackTag': tag,
      });
      if (!mounted) return;
      if (response != null && response['code'] == 200) {
        final data = response['data'] as Map<String, dynamic>?;
        final learningMessage = data?['learningMessage']?.toString();
        setState(() {
          _feedbackTag = tag;
          _feedbackLearningMessage = learningMessage;
          _isSavingFeedback = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(learningMessage ?? _feedbackLabel(tag))),
        );
        await _refreshPreferenceInsights();
      } else {
        setState(() => _isSavingFeedback = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response?['message']?.toString() ?? '保存反馈失败')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingFeedback = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存反馈失败: $e')),
      );
    }
  }

  String _feedbackLabel(String tag) {
    switch (tag) {
      case 'too_easy':
        return '已记录：本次推荐太简单';
      case 'too_hard':
        return '已记录：本次推荐太难';
      case 'dislike':
        return '已记录：你不喜欢这类推荐';
      default:
        return '已记录：本次推荐很合适';
    }
  }

  Future<void> _refreshPreferenceInsights() async {
    final userId = await StorageService.getUserId();
    if (userId == null || userId.isEmpty || !mounted) return;

    setState(() => _isRefreshingInsights = true);
    try {
      final response = await _apiService.get(
        '/user/preferences/insights',
        params: {'userId': userId},
      );

      if (!mounted) return;
      if (response != null && response['code'] == 200 && response['data'] is Map<String, dynamic>) {
        setState(() {
          _latestLearningInsights = response['data'] as Map<String, dynamic>;
          _isRefreshingInsights = false;
        });
      } else {
        setState(() => _isRefreshingInsights = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRefreshingInsights = false);
      debugPrint('刷新偏好洞察失败: $e');
    }
  }

  String _formatCompletionRate(dynamic rateValue) {
    if (rateValue is num) {
      final percent = rateValue <= 1 ? rateValue * 100 : rateValue.toDouble();
      return '${percent.toStringAsFixed(1)}%';
    }
    return '--';
  }

  List<String> _preferenceMatchedItems() {
    return (_preferenceApplied?['matched_items'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  int _estimatedDurationSeconds() {
    final durationFromMotion = widget.motionData?['duration'];
    if (durationFromMotion is int && durationFromMotion > 0) {
      return durationFromMotion;
    }
    final description = widget.motionData?['description']?.toString() ?? '';
    final match = RegExp(r'(\d+)').firstMatch(description);
    if (match != null) {
      final value = int.tryParse(match.group(1)!);
      if (value != null) {
        return description.contains('分钟') ? value * 60 : value;
      }
    }
    final steps = widget.motionData?['steps'] as List<dynamic>? ?? [];
    return steps.isNotEmpty ? steps.length * 30 : 60;
  }

  Future<void> _initVideoController({bool autoPlay = false}) async {
    if (!_supportsEmbeddedVideo || _selectedVideo == null) return;

    // 先释放旧的
    _controller?.removeListener(_handleVideoProgress);
    _controller?.dispose();
    _controller = null;
    _isControllerInitialized = false;

    final encodedName = Uri.encodeComponent(_selectedVideo!);
    final url = '${ApiService.baseUrl}/video/play?filename=$encodedName';

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
      controller.setLooping(false);
      controller.addListener(_handleVideoProgress);
      if (autoPlay) {
        await controller.play();
      }
      setState(() {
        _controller = controller;
        _isControllerInitialized = true;
        _isPlaying = autoPlay;
      });
    } catch (e) {
      debugPrint('视频初始化失败: $e');
    }
  }

  void _handleVideoProgress() {
    if (_controller == null || !_controller!.value.isInitialized || _isAdvancingVideo) {
      return;
    }

    final value = _controller!.value;
    if (value.duration.inMilliseconds <= 0) return;

    final isFinished = value.position >= value.duration - const Duration(milliseconds: 300);
    if (isFinished && !value.isPlaying) {
      _playNextMatchedVideo();
    }
  }

  Future<void> _playNextMatchedVideo() async {
    if (_matchedVideos.isEmpty || _selectedVideo == null) return;
    final currentIndex = _matchedVideos.indexOf(_selectedVideo!);
    if (currentIndex < 0 || currentIndex >= _matchedVideos.length - 1) {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
      return;
    }

    _isAdvancingVideo = true;
    if (mounted) {
      setState(() {
        _selectedVideo = _matchedVideos[currentIndex + 1];
        _currentStep = currentIndex + 1;
      });
    }
    await _initVideoController(autoPlay: true);
    _isAdvancingVideo = false;
  }

  List<String> _matchVideosToActions(List<String> videos) {
    final actions = (widget.motionData?['actions'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final orderedMatches = <String>[];

    for (final action in actions) {
      final actionName = action['name']?.toString() ?? '';
      final matched = _findBestVideoForAction(actionName, videos);
      if (matched != null && !orderedMatches.contains(matched)) {
        orderedMatches.add(matched);
      }
    }

    return orderedMatches.isNotEmpty ? orderedMatches : videos;
  }

  String? _findBestVideoForAction(String actionName, List<String> videos) {
    if (actionName.isEmpty) return null;
    final normalizedAction = _normalizeName(actionName);

    for (final video in videos) {
      if (_normalizeName(video) == normalizedAction) {
        return video;
      }
    }

    for (final video in videos) {
      final normalizedVideo = _normalizeName(video);
      if (normalizedVideo.contains(normalizedAction) || normalizedAction.contains(normalizedVideo)) {
        return video;
      }
    }
    return null;
  }

  String _normalizeName(String value) {
    return value
        .replaceAll('.mp4', '')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^\u4e00-\u9fa5A-Za-z0-9]'), '')
        .toLowerCase();
  }

  Widget _buildVideoArea() {
    if (_supportsEmbeddedVideo && _controller != null && _isControllerInitialized) {
      return GestureDetector(
        onTap: _togglePlayPause,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
            if (!_isPlaying)
              const Icon(
                Icons.play_circle_fill,
                size: 72,
                color: Colors.white70,
              ),
          ],
        ),
      );
    }

    // 非移动端或未初始化时的占位 UI
    if (_selectedVideo != null) {
      return Column(
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
            '点击下方按钮在浏览器/播放器中打开',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      );
    }

    return Center(
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
    );
  }

  void _togglePlayPause() {
    if (!_supportsEmbeddedVideo || _controller == null || !_isControllerInitialized) {
      return;
    }
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final motionName = widget.motionData?['motion_name'] ?? '微运动指导';
    final description = widget.motionData?['description'] ?? '';
    final actions = (widget.motionData?['actions'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final preferenceSummary = _preferenceApplied?['summary']?.toString();
    final preferenceMatchedItems = _preferenceMatchedItems();
    final steps = actions.isNotEmpty
        ? actions.map((action) => action['name']?.toString() ?? '').where((name) => name.isNotEmpty).toList()
        : (widget.motionData?['steps'] as List<dynamic>? ?? []);

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
                    color: Colors.black,
                    child: _buildVideoArea(),
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
                        if (_matchedVideos.isEmpty)
                          const Text('当前方案没有匹配到可播放的视频')
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _matchedVideos.map((video) {
                              final isSelected = _selectedVideo == video;
                              return ChoiceChip(
                                label: Text(video, style: const TextStyle(fontSize: 12)),
                                selected: isSelected,
                                  onSelected: (selected) async {
                                   setState(() {
                                     _selectedVideo = selected ? video : null;
                                     _currentStep = _matchedVideos.indexOf(video).clamp(0, _matchedVideos.length - 1);
                                     _isPlaying = false;
                                   });
                                   if (_supportsEmbeddedVideo && selected) {
                                     await _initVideoController();
                                   }
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
                             onPressed: _matchedVideos.isNotEmpty ? () async {
                               if (_currentStep > 0) {
                                 setState(() {
                                   _currentStep--;
                                   _selectedVideo = _matchedVideos[_currentStep];
                                   _isPlaying = false;
                                 });
                                 await _initVideoController();
                               }
                             } : null,
                             icon: const Icon(Icons.skip_previous, size: 36),
                             color: Colors.blue,
                           ),
                           const SizedBox(width: 16),
                            _supportsEmbeddedVideo
                                ? ElevatedButton.icon(
                                    onPressed: _togglePlayPause,
                                    icon: Icon(
                                      _isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                    ),
                                    label:
                                        Text(_isPlaying ? '暂停' : '顺序播放'),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: _openVideo,
                                   icon: const Icon(Icons.open_in_new),
                                   label: const Text('在浏览器中打开'),
                                 ),
                          const SizedBox(width: 16),
                           IconButton(
                              onPressed: _matchedVideos.isNotEmpty ? () async {
                                if (_currentStep < _matchedVideos.length - 1) {
                                  setState(() {
                                    _currentStep++;
                                    _selectedVideo = _matchedVideos[_currentStep];
                                    _isPlaying = false;
                                  });
                                  await _initVideoController();
                                }
                             } : null,
                             icon: const Icon(Icons.skip_next, size: 36),
                             color: Colors.blue,
                           ),
                        ],
                      ),
                    ),
                  if (_selectedVideo != null && steps.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _recordSaved || _isSavingRecord ? null : _saveExerciseRecord,
                              icon: _isSavingRecord
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Icon(_recordSaved ? Icons.check_circle : Icons.task_alt),
                              label: Text(_recordSaved ? '本次运动已记录' : '完成本次运动并写入健康数据'),
                            ),
                          ),
                          if (_recordSaved) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isSavingFeedback ? null : _showFeedbackDialog,
                                icon: _isSavingFeedback
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.rate_review_outlined),
                                label: Text(_feedbackTag == null ? '评价本次推荐' : _feedbackLabel(_feedbackTag!)),
                              ),
                            ),
                            if (_feedbackLearningMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _feedbackLearningMessage!,
                                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                              ),
                            ],
                            if (_isRefreshingInsights) ...[
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  SizedBox(
                                    height: 12,
                                    width: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text('正在更新偏好学习洞察...'),
                                ],
                              ),
                            ],
                            if (_latestLearningInsights != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.psychology, size: 18, color: Colors.blue[700]),
                                        const SizedBox(width: 6),
                                        Text(
                                          '偏好学习已更新',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _latestLearningInsights!['summary']?.toString() ?? '已结合最新反馈更新推荐偏好。',
                                      style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '近30天训练 ${_latestLearningInsights!['totalSessions'] ?? 0} 次，完成率 ${_formatCompletionRate(_latestLearningInsights!['completionRate'])}',
                                      style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
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
                        if (preferenceSummary != null && preferenceSummary.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.tune, size: 18, color: Colors.green[700]),
                                    const SizedBox(width: 6),
                                    Text(
                                      '为什么给你推荐这个视频',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  preferenceSummary,
                                  style: TextStyle(fontSize: 14, color: Colors.green[900], height: 1.5),
                                ),
                                if (preferenceMatchedItems.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  ...preferenceMatchedItems.map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('• ', style: TextStyle(color: Colors.green[800])),
                                          Expanded(
                                            child: Text(
                                              item,
                                              style: TextStyle(fontSize: 13, color: Colors.green[800], height: 1.4),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (steps.isNotEmpty) ...[
                          Text(
                            '运动步骤 (第 ${_currentStep + 1}/${steps.length} 步)',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                           Card(
                            color: _isPlaying
                                ? Colors.blue[50]
                                : Colors.grey[100],
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
                                       actions.isNotEmpty
                                           ? '${actions[_currentStep]['name'] ?? ''}\n做法：${actions[_currentStep]['instruction'] ?? ''}\n注意：${actions[_currentStep]['warning'] ?? ''}'
                                           : steps[_currentStep].toString(),
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
                                   actions.isNotEmpty
                                       ? '${actions[entry.key]['name'] ?? ''}（${actions[entry.key]['seconds'] ?? 20}秒）'
                                       : entry.value.toString(),
                                   style: TextStyle(
                                     fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                   ),
                                 ),
                                 subtitle: actions.isNotEmpty
                                     ? Text(actions[entry.key]['instruction']?.toString() ?? '')
                                     : null,
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
