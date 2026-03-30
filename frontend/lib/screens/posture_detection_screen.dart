import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../constants/guided_motion_catalog.dart';

class _PoseSnapshot {
  const _PoseSnapshot({
    required this.shoulderWidth,
    required this.avgShoulderY,
    required this.wristSpan,
    required this.avgWristY,
  });

  final double shoulderWidth;
  final double avgShoulderY;
  final double wristSpan;
  final double avgWristY;
}

class PostureDetectionScreen extends StatefulWidget {
  const PostureDetectionScreen({super.key, this.motionData});

  final Map<String, dynamic>? motionData;

  @override
  State<PostureDetectionScreen> createState() => _PostureDetectionScreenState();
}

class _PostureDetectionScreenState extends State<PostureDetectionScreen> {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
  );

  late final GuidedMotionPlan _guidedPlan;
  CameraController? _cameraController;
  final List<_PoseSnapshot> _motionHistory = [];
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
  int _currentActionIndex = 0;
  int _guidedRemainingSeconds = 0;
  String _guidedCue = '点击开始跟练';
  String _guidedFeedbackTitle = '准备开始';
  String _guidedTargetLabel = '左侧';
  bool _showSwitchOverlay = false;
  String _switchOverlayText = '左侧';

  GuidedMotionSession get _currentSession => _guidedPlan.sessions[_currentActionIndex];

  Color get _guidedFeedbackColor {
    if (_guidedFeedbackTitle.contains('标准') || _guidedFeedbackTitle.contains('完成')) {
      return Colors.green;
    }
    if (_guidedFeedbackTitle.contains('继续') || _guidedFeedbackTitle.contains('方向')) {
      return Colors.teal;
    }
    if (_guidedFeedbackTitle.contains('不够') || _guidedFeedbackTitle.contains('等待')) {
      return Colors.orange;
    }
    return Colors.blueGrey;
  }

  @override
  void initState() {
    super.initState();
    final builtPlan = GuidedMotionCatalog.buildPlan(widget.motionData);
    _guidedPlan = builtPlan.sessions.isEmpty ? GuidedMotionCatalog.buildPlan(null) : builtPlan;
    _guidedRemainingSeconds = _guidedPlan.sessions.first.seconds;
    _guidedCue = '点击开始跟练，先做 ${_guidedPlan.sessions.first.definition.title}。';
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

      if (poses.isNotEmpty) {
        _appendMotionSnapshot(poses.first);
      }

      if (!mounted) return;
      setState(() {
        _poses = poses;
        _detectedPointCount = pointCount;
        _imageSize = inputImage.metadata?.size ?? Size(image.width.toDouble(), image.height.toDouble());
        _statusText = poses.isEmpty ? '未检测到上半身，请调整距离和光线' : '已检测到人体关键点';
        _evaluateGuidedFeedback(poses);
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

  void _appendMotionSnapshot(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    if (leftShoulder == null || rightShoulder == null || leftWrist == null || rightWrist == null) {
      return;
    }

    _motionHistory.add(
      _PoseSnapshot(
        shoulderWidth: (rightShoulder.x - leftShoulder.x).abs().clamp(1, double.infinity),
        avgShoulderY: (leftShoulder.y + rightShoulder.y) / 2,
        wristSpan: (rightWrist.x - leftWrist.x).abs(),
        avgWristY: (leftWrist.y + rightWrist.y) / 2,
      ),
    );

    if (_motionHistory.length > 24) {
      _motionHistory.removeAt(0);
    }
  }

  Future<void> _toggleCamera() async {
    _useFrontCamera = !_useFrontCamera;
    await _initializeCamera();
  }

  String get _currentTargetLabel {
    if (_currentSession.definition.id != 'neck_tilt') {
      return '当前动作';
    }
    final half = math.max(1, (_currentSession.seconds / 2).floor());
    final segment = ((_currentSession.seconds - _guidedRemainingSeconds) ~/ half) % 2;
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
        if (_currentActionIndex >= _guidedPlan.sessions.length - 1) {
          timer.cancel();
          setState(() {
            _guidedRunning = false;
            _guidedRemainingSeconds = 0;
            _guidedTargetLabel = _currentTargetLabel;
            _guidedFeedbackTitle = '整套动作完成';
            _guidedCue = '演示版实时跟练已结束，可以直接录制演示视频。';
          });
        } else {
          setState(() {
            _currentActionIndex += 1;
            _guidedRemainingSeconds = _currentSession.seconds;
            _guidedTargetLabel = _currentTargetLabel;
            _guidedFeedbackTitle = '切换动作';
            _guidedCue = '切换到 ${_currentSession.definition.title}，请按提示继续跟练。';
          });
          _showSideSwitchOverlay('切换动作：${_currentSession.definition.title}');
        }
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
        _currentActionIndex = 0;
        _guidedRemainingSeconds = _guidedPlan.sessions.first.seconds;
      }
      _guidedRunning = true;
      _guidedTargetLabel = _currentTargetLabel;
    });
    _showSideSwitchOverlay('开始：${_currentSession.definition.title}');
  }

  void _resetGuidedTraining() {
    _guidedTimer?.cancel();
    _switchOverlayTimer?.cancel();
    setState(() {
      _guidedRunning = false;
      _currentActionIndex = 0;
      _guidedRemainingSeconds = _guidedPlan.sessions.first.seconds;
      _guidedTargetLabel = '左侧';
      _guidedFeedbackTitle = '准备开始';
      _guidedCue = '点击开始跟练，先做 ${_guidedPlan.sessions.first.definition.title}。';
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

  void _evaluateGuidedFeedback(List<Pose> poses) {
    if (_guidedRemainingSeconds == 0) {
      _guidedFeedbackTitle = '整套动作完成';
      _guidedCue = '演示版实时跟练已结束，可以直接录制演示视频。';
      return;
    }
    if (poses.isEmpty) {
      _guidedFeedbackTitle = '等待进入画面';
      _guidedCue = '请让头部、双肩和双臂进入画面，再开始 ${_currentSession.definition.title}。';
      return;
    }

    switch (_currentSession.definition.id) {
      case 'neck_tilt':
        _evaluateNeckTilt(poses.first);
        break;
      case 'shrug':
        _evaluateShrug();
        break;
      case 'shoulder_circle':
        _evaluateShoulderCircle();
        break;
      case 'chest_open':
        _evaluateChestOpen(poses.first);
        break;
      default:
        _guidedFeedbackTitle = '继续动作';
        _guidedCue = _currentSession.definition.shortInstruction;
    }
  }

  void _evaluateNeckTilt(Pose pose) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    if (nose == null || leftShoulder == null || rightShoulder == null) {
      _guidedFeedbackTitle = '等待颈肩关键点';
      _guidedCue = '请让头部和双肩完整可见。';
      return;
    }

    final shoulderCenterX = (leftShoulder.x + rightShoulder.x) / 2;
    final shoulderWidth = (rightShoulder.x - leftShoulder.x).abs().clamp(1, double.infinity);
    final tilt = (nose.x - shoulderCenterX) / shoulderWidth;
    final targetLeft = _currentTargetLabel == '左侧';
    final tiltOk = targetLeft ? tilt < -0.12 : tilt > 0.12;
    final tiltGreat = targetLeft ? tilt < -0.20 : tilt > 0.20;

    if (!tiltOk) {
      _guidedFeedbackTitle = '继续侧屈';
      _guidedCue = '耳朵继续靠近$_currentTargetLabel肩膀，头不要前伸。';
      return;
    }
    _guidedFeedbackTitle = tiltGreat ? '动作很标准' : '方向正确';
    _guidedCue = '保持向$_currentTargetLabel侧屈，肩膀放松，呼吸自然。';
  }

  void _evaluateShrug() {
    if (_motionHistory.length < 8) {
      _guidedFeedbackTitle = '开始提肩';
      _guidedCue = '双肩向上提起，再慢慢放下。';
      return;
    }

    final range = _historyRange((item) => item.avgShoulderY);
    final shoulderWidth = _motionHistory.last.shoulderWidth;
    if (range < shoulderWidth * 0.08) {
      _guidedFeedbackTitle = '动作幅度不够';
      _guidedCue = '双肩再向上提一点，再慢慢放下。';
      return;
    }
    _guidedFeedbackTitle = range > shoulderWidth * 0.14 ? '节奏很好' : '动作已识别';
    _guidedCue = '双肩起伏已经被识别到，继续保持提肩和放松的循环。';
  }

  void _evaluateShoulderCircle() {
    if (_motionHistory.length < 8) {
      _guidedFeedbackTitle = '开始绕肩';
      _guidedCue = '双肩向前上后下缓慢画圈。';
      return;
    }
    final shoulderRange = _historyRange((item) => item.avgShoulderY);
    final wristRange = _historyRange((item) => item.avgWristY);
    final shoulderWidth = _motionHistory.last.shoulderWidth;
    if (shoulderRange < shoulderWidth * 0.07 || wristRange < shoulderWidth * 0.09) {
      _guidedFeedbackTitle = '动作还不够明显';
      _guidedCue = '让肩部画圈更完整一点，动作尽量连贯。';
      return;
    }
    _guidedFeedbackTitle = shoulderRange > shoulderWidth * 0.13 ? '绕肩很流畅' : '继续保持';
    _guidedCue = '很好，继续保持肩部环绕的连续节奏。';
  }

  void _evaluateChestOpen(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    if (leftShoulder == null || rightShoulder == null || leftWrist == null || rightWrist == null) {
      _guidedFeedbackTitle = '等待手臂关键点';
      _guidedCue = '请让双手、双肩都进入画面。';
      return;
    }

    final shoulderWidth = (rightShoulder.x - leftShoulder.x).abs().clamp(1, double.infinity);
    final wristSpan = (rightWrist.x - leftWrist.x).abs();
    final armsOpen = wristSpan > shoulderWidth * 1.55;
    final excellent = wristSpan > shoulderWidth * 1.85;
    if (!armsOpen) {
      _guidedFeedbackTitle = '再把手臂打开一点';
      _guidedCue = '双臂向身体两侧继续展开，胸口向前打开。';
      return;
    }
    _guidedFeedbackTitle = excellent ? '扩胸动作很标准' : '继续保持扩胸';
    _guidedCue = '保持双臂打开和胸口展开，停留 1 到 2 秒再回位。';
  }

  double _historyRange(double Function(_PoseSnapshot item) selector) {
    if (_motionHistory.isEmpty) {
      return 0;
    }
    final values = _motionHistory.map(selector).toList();
    return values.reduce(math.max) - values.reduce(math.min);
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
        title: const Text('实时跟练指导'),
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
                    _buildActionQueueCard(),
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
        subtitle: Text(
          _guidedRunning
              ? '当前跟练动作：${_currentSession.definition.title}'
              : '已支持 ${_guidedPlan.sessions.length} 个演示动作实时指导',
        ),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_currentSession.definition.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(_currentSession.definition.shortInstruction),
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
                _buildGuideChip('动作', _currentSession.definition.title),
                _buildGuideChip('目标', _guidedTargetLabel),
                _buildGuideChip('剩余时间', _formatCountdown(_guidedRemainingSeconds)),
                _buildGuideChip('状态', _guidedRunning ? '进行中' : (_guidedRemainingSeconds == 0 ? '已完成' : '未开始')),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _guidedFeedbackColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _guidedFeedbackTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _guidedFeedbackColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _guidedCue,
                    style: const TextStyle(height: 1.45),
                  ),
                ],
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('拍摄建议', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_currentSession.definition.cameraHint),
            const SizedBox(height: 4),
            const Text('背景尽量简单，保持光线充足。'),
            const SizedBox(height: 4),
            const Text('拍视频时建议打开骨架，能更直观看到识别效果。'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionQueueCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('本次可演示的跟练动作', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._guidedPlan.sessions.asMap().entries.map((entry) {
              final isCurrent = entry.key == _currentActionIndex;
              final session = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCurrent ? session.definition.accentColor.withOpacity(0.10) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrent ? session.definition.accentColor.withOpacity(0.35) : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isCurrent ? session.definition.accentColor : Colors.grey.shade300,
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          color: isCurrent ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(session.definition.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                    Text('${session.seconds}s'),
                  ],
                ),
              );
            }),
            if (_guidedPlan.unsupportedActions.isNotEmpty)
              Text(
                '暂未做实时识别的 AI 动作：${_guidedPlan.unsupportedActions.join('、')}',
                style: TextStyle(color: Colors.orange.shade900, height: 1.4),
              ),
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
