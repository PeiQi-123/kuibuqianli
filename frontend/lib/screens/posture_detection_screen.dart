import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PostureDetectionScreen extends StatefulWidget {
  const PostureDetectionScreen({super.key});

  @override
  State<PostureDetectionScreen> createState() => _PostureDetectionScreenState();
}

class _PostureDetectionScreenState extends State<PostureDetectionScreen> {
  static const int _guidedTotalSeconds = 60;

  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
  );

  CameraController? _cameraController;
  List<Pose> _poses = const [];
  bool _isBusy = false;
  bool _isInitialized = false;
  bool _showSkeleton = true;
  bool _useFrontCamera = true;
  String _statusText = '正在初始化摄像头...';
  String? _errorText;
  int _detectedPointCount = 0;
  DateTime? _lastFrameAt;
  double _estimatedFps = 0;
  InputImageRotation _inputImageRotation = InputImageRotation.rotation0deg;
  Size _imageSize = Size.zero;
  Timer? _guidedTimer;
  Timer? _switchOverlayTimer;
  bool _guidedRunning = false;
  int _guidedRemainingSeconds = _guidedTotalSeconds;
  String _guidedCue = '点击开始跟练，先做 1 分钟颈部侧屈拉伸。';
  String _guidedTargetLabel = '左侧';
  bool _showSwitchOverlay = false;
  String _switchOverlayText = '左侧';

  @override
  void initState() {
    super.initState();
    unawaited(_initializeCamera());
  }

  @override
  void dispose() {
    unawaited(_disposeResources());
    super.dispose();
  }

  Future<void> _disposeResources() async {
    _guidedTimer?.cancel();
    _switchOverlayTimer?.cancel();
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      await controller.dispose();
    }
    await _poseDetector.close();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _errorText = null;
      _statusText = '正在初始化摄像头...';
      _isInitialized = false;
    });

    final previousController = _cameraController;
    _cameraController = null;
    if (previousController != null) {
      if (previousController.value.isStreamingImages) {
        await previousController.stopImageStream();
      }
      await previousController.dispose();
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('未找到可用摄像头');
      }

      final selected = cameras.firstWhere(
        (camera) => camera.lensDirection == (_useFrontCamera ? CameraLensDirection.front : CameraLensDirection.back),
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      _inputImageRotation = _rotationFromSensor(selected.sensorOrientation);
      _cameraController = controller;

      await controller.startImageStream((image) {
        if (_isBusy || !mounted) return;
        _isBusy = true;
        unawaited(_processCameraImage(image));
      });

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _statusText = '摄像头已开启，请让上半身进入画面';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString();
        _statusText = '初始化失败';
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        return;
      }

      final poses = await _poseDetector.processImage(inputImage);
      final pointCount = poses.isEmpty ? 0 : poses.first.landmarks.length;
      final now = DateTime.now();
      if (_lastFrameAt != null) {
        final diffMs = now.difference(_lastFrameAt!).inMilliseconds;
        if (diffMs > 0) {
          _estimatedFps = 1000 / diffMs;
        }
      }
      _lastFrameAt = now;

      if (!mounted) return;
      setState(() {
        _poses = poses;
        _detectedPointCount = pointCount;
        _imageSize = inputImage.metadata?.size ?? Size(image.width.toDouble(), image.height.toDouble());
        _statusText = poses.isEmpty ? '未检测到上半身，请调整距离和光线' : '已检测到人体关键点';
        _guidedTargetLabel = _currentTargetLabel;
        _guidedCue = _buildGuidedCue(poses);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = '姿态识别失败：$e';
      });
    } finally {
      _isBusy = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) {
      return null;
    }

    if (Platform.isAndroid && format != InputImageFormat.nv21) {
      if (mounted) {
        setState(() {
          _statusText = '当前设备返回的相机帧格式暂不兼容：$format';
        });
      }
      return null;
    }

    if (Platform.isIOS && format != InputImageFormat.bgra8888) {
      return null;
    }

    final bytes = _concatenatePlanes(image.planes);
    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: _inputImageRotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final builder = BytesBuilder(copy: false);
    for (final plane in planes) {
      builder.add(plane.bytes);
    }
    return builder.toBytes();
  }

  InputImageRotation _rotationFromSensor(int sensorOrientation) {
    return InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg;
  }

  Future<void> _toggleCamera() async {
    _useFrontCamera = !_useFrontCamera;
    await _initializeCamera();
  }

  String get _currentTargetLabel {
    final segment = ((_guidedTotalSeconds - _guidedRemainingSeconds) ~/ 15) % 2;
    return segment == 0 ? '左侧' : '右侧';
  }

  void _toggleGuidedTraining() {
    if (_guidedRunning) {
      _guidedTimer?.cancel();
      setState(() {
        _guidedRunning = false;
      });
      return;
    }

    _guidedTimer?.cancel();
    _guidedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final previousTarget = _currentTargetLabel;
      if (_guidedRemainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _guidedRunning = false;
          _guidedRemainingSeconds = 0;
          _guidedTargetLabel = _currentTargetLabel;
          _guidedCue = '本轮 1 分钟颈部侧屈拉伸已完成，放松肩颈并调整呼吸。';
        });
        return;
      }

      setState(() {
        _guidedRemainingSeconds -= 1;
        _guidedTargetLabel = _currentTargetLabel;
      });

      if (previousTarget != _currentTargetLabel) {
        _showSideSwitchOverlay(_currentTargetLabel);
      }
    });

    setState(() {
      if (_guidedRemainingSeconds == 0) {
        _guidedRemainingSeconds = _guidedTotalSeconds;
      }
      _guidedRunning = true;
      _guidedTargetLabel = _currentTargetLabel;
    });
  }

  void _resetGuidedTraining() {
    _guidedTimer?.cancel();
    _switchOverlayTimer?.cancel();
    setState(() {
      _guidedRunning = false;
      _guidedRemainingSeconds = _guidedTotalSeconds;
      _guidedTargetLabel = '左侧';
      _guidedCue = '点击开始跟练，先做 1 分钟颈部侧屈拉伸。';
      _showSwitchOverlay = false;
    });
  }

  void _showSideSwitchOverlay(String targetLabel) {
    _switchOverlayTimer?.cancel();
    setState(() {
      _switchOverlayText = '切换到$targetLabel';
      _showSwitchOverlay = true;
    });
    _switchOverlayTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _showSwitchOverlay = false;
      });
    });
  }

  String _buildGuidedCue(List<Pose> poses) {
    if (_guidedRemainingSeconds == 0) {
      return '本轮 1 分钟颈部侧屈拉伸已完成，放松肩颈并调整呼吸。';
    }
    if (poses.isEmpty) {
      return '请让头部和双肩完整进入画面，再开始跟练。';
    }

    final pose = poses.first;
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    if (nose == null || leftShoulder == null || rightShoulder == null) {
      return '请保持头部和双肩可见，方便识别颈部动作。';
    }

    final shoulderCenterX = (leftShoulder.x + rightShoulder.x) / 2;
    final shoulderWidth = (rightShoulder.x - leftShoulder.x).abs().clamp(1, double.infinity);
    final normalizedTilt = (nose.x - shoulderCenterX) / shoulderWidth;
    final shoulderHeightDiff = (leftShoulder.y - rightShoulder.y).abs();
    final targetLeft = _currentTargetLabel == '左侧';
    final tiltOk = targetLeft ? normalizedTilt < -0.10 : normalizedTilt > 0.10;
    final strongTilt = targetLeft ? normalizedTilt < -0.18 : normalizedTilt > 0.18;
    final shouldersRelaxed = shoulderHeightDiff < 26;

    if (!tiltOk) {
      return '头部向$_currentTargetLabel继续侧屈一点，动作放慢，避免转头。';
    }
    if (!shouldersRelaxed) {
      return '很好，继续向$_currentTargetLabel侧屈，同时把双肩放松，不要耸肩。';
    }
    if (strongTilt) {
      return '动作很标准，保持向$_currentTargetLabel侧屈，呼吸放松。';
    }
    return '再向$_currentTargetLabel轻轻靠近一点，保持肩膀稳定。';
  }

  String _formatCountdown(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remain = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remain';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('姿态检测测试'),
        actions: [
          IconButton(
            onPressed: _initializeCamera,
            tooltip: '重新初始化',
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _toggleCamera,
            tooltip: '切换摄像头',
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape = orientation == Orientation.landscape;
                final previewHeight = isLandscape
                    ? constraints.maxHeight - 24
                    : constraints.maxHeight * 0.56;

                final preview = SizedBox(
                  height: previewHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      color: Colors.black,
                      child: _buildPreviewArea(),
                    ),
                  ),
                );

                final panels = Column(
                  children: [
                    _buildGuidedTrainingCard(),
                    const SizedBox(height: 12),
                    _buildDebugSummaryCard(),
                  ],
                );

                if (isLandscape) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 8, child: preview),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: SingleChildScrollView(child: panels),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      children: [
                        preview,
                        const SizedBox(height: 12),
                        panels,
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPreviewArea() {
    if (_errorText != null) {
      return _buildPlaceholder(
        icon: Icons.error_outline,
        title: '姿态检测不可用',
        subtitle: _errorText!,
      );
    }

    final controller = _cameraController;
    if (!_isInitialized || controller == null || !controller.value.isInitialized) {
      return _buildPlaceholder(
        icon: Icons.videocam_outlined,
        title: '正在准备摄像头',
        subtitle: _statusText,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = controller.value.previewSize;
        if (previewSize == null) {
          return _buildPlaceholder(
            icon: Icons.videocam_off_outlined,
            title: '无法显示预览',
            subtitle: '摄像头预览尺寸不可用',
          );
        }

        final rotatedPreviewSize = Size(previewSize.height, previewSize.width);
        final fittedSizes = applyBoxFit(BoxFit.contain, rotatedPreviewSize, constraints.biggest);
        final destinationSize = fittedSizes.destination;
        final dx = (constraints.maxWidth - destinationSize.width) / 2;
        final dy = (constraints.maxHeight - destinationSize.height) / 2;

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: dx,
              top: dy,
              width: destinationSize.width,
              height: destinationSize.height,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: rotatedPreviewSize.width,
                  height: rotatedPreviewSize.height,
                  child: CameraPreview(controller),
                ),
              ),
            ),
            if (_showSkeleton)
              Positioned(
                left: dx,
                top: dy,
                width: destinationSize.width,
                height: destinationSize.height,
                child: CustomPaint(
                  painter: _PoseOverlayPainter(
                    poses: _poses,
                    imageSize: _imageSize,
                    rotation: _inputImageRotation,
                    isFrontCamera: _useFrontCamera,
                  ),
                ),
              ),
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusText,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showSwitchOverlay ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _switchOverlayText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholder({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Colors.white70),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: ListTile(
        leading: Icon(
          _poses.isEmpty ? Icons.accessibility_new_outlined : Icons.accessibility_new,
          color: _poses.isEmpty ? Colors.orange.shade700 : Colors.green.shade700,
        ),
        title: Text(_poses.isEmpty ? '等待检测人体' : '已识别到人体关键点'),
        subtitle: Text(_guidedRunning ? '当前跟练目标：颈部向$_guidedTargetLabel侧屈' : '第一版先做 1 分钟颈部侧屈拉伸跟练。'),
        trailing: Switch(
          value: _showSkeleton,
          onChanged: (value) => setState(() => _showSkeleton = value),
        ),
      ),
    );
  }

  Widget _buildGuidedTrainingCard() {
    final progress = (_guidedTotalSeconds - _guidedRemainingSeconds) / _guidedTotalSeconds;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.timer_outlined, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1分钟颈部侧屈拉伸', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('每 15 秒自动切换左右侧，边做边看纠正提示。'),
                    ],
                  ),
                ),
                Text(
                  _formatCountdown(_guidedRemainingSeconds),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildGuideChip('当前目标', _guidedTargetLabel),
                _buildGuideChip('剩余时间', _formatCountdown(_guidedRemainingSeconds)),
                _buildGuideChip('状态', _guidedRunning ? '进行中' : (_guidedRemainingSeconds == 0 ? '已完成' : '未开始')),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _guidedCue,
                style: const TextStyle(height: 1.45),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleGuidedTraining,
                    icon: Icon(_guidedRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(_guidedRunning ? '暂停跟练' : (_guidedRemainingSeconds == 0 ? '重新开始' : '开始跟练')),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _resetGuidedTraining,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重置'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(fontSize: 12),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _buildStatItem('关键点', '$_detectedPointCount')),
            Expanded(child: _buildStatItem('镜头', _useFrontCamera ? '前置' : '后置')),
            Expanded(child: _buildStatItem('帧率', _estimatedFps == 0 ? '-' : '${_estimatedFps.toStringAsFixed(1)} fps')),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }

  Widget _buildTipsCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('测试建议', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('1. 让头部、双肩、双肘、双腕进入画面。'),
            SizedBox(height: 4),
            Text('2. 背景尽量简单，保持光线充足。'),
            SizedBox(height: 4),
            Text('3. 先验证骨架是否稳定，再做动作规则判断。'),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _buildStatusCard()),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatsCard(),
            const SizedBox(height: 12),
            _buildTipsCard(),
          ],
        ),
      ),
    );
  }
}

class _PoseOverlayPainter extends CustomPainter {
  const _PoseOverlayPainter({
    required this.poses,
    required this.imageSize,
    required this.rotation,
    required this.isFrontCamera,
  });

  final List<Pose> poses;
  final Size imageSize;
  final InputImageRotation rotation;
  final bool isFrontCamera;

  static const List<List<PoseLandmarkType>> _connections = [
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    [PoseLandmarkType.nose, PoseLandmarkType.leftShoulder],
    [PoseLandmarkType.nose, PoseLandmarkType.rightShoulder],
  ];

  static const List<PoseLandmarkType> _upperBodyPoints = [
    PoseLandmarkType.nose,
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (poses.isEmpty || imageSize == Size.zero) {
      return;
    }

    final linePaint = Paint()
      ..color = const Color(0xFF5EEAD4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final pointPaint = Paint()
      ..color = const Color(0xFFFACC15)
      ..style = PaintingStyle.fill;

    for (final pose in poses) {
      for (final pair in _connections) {
        final start = pose.landmarks[pair.first];
        final end = pose.landmarks[pair.last];
        if (start == null || end == null) continue;
        final startOffset = _translate(start, size);
        final endOffset = _translate(end, size);
        canvas.drawLine(startOffset, endOffset, linePaint);
      }

      for (final type in _upperBodyPoints) {
        final landmark = pose.landmarks[type];
        if (landmark == null) continue;
        final offset = _translate(landmark, size);
        canvas.drawCircle(offset, 5, pointPaint);
      }
    }
  }

  Offset _translate(PoseLandmark landmark, Size canvasSize) {
    final effectiveImageSize = switch (rotation) {
      InputImageRotation.rotation90deg || InputImageRotation.rotation270deg => Size(imageSize.height, imageSize.width),
      _ => imageSize,
    };

    double translatedX = landmark.x / effectiveImageSize.width * canvasSize.width;
    double translatedY = landmark.y / effectiveImageSize.height * canvasSize.height;

    if (isFrontCamera) {
      translatedX = canvasSize.width - translatedX;
    }

    return Offset(translatedX, translatedY);
  }

  @override
  bool shouldRepaint(covariant _PoseOverlayPainter oldDelegate) {
    return oldDelegate.poses != poses ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.rotation != rotation ||
        oldDelegate.isFrontCamera != isFrontCamera;
  }
}
