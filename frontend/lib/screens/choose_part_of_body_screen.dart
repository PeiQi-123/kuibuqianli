// lib/screens/choose_part_of_body_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';

// 身体部位枚举
enum BodyPart {
  head('头部', 'head'),
  neck('颈部', 'neck'),
  leftShoulder('左肩', 'left_shoulder'),
  rightShoulder('右肩', 'right_shoulder'),
  chest('胸部', 'chest'),
  waist('腰部', 'waist'),
  leftElbow('左手肘', 'left_elbow'),
  rightElbow('右手肘', 'right_elbow'),
  leftHand('左手', 'left_hand'),
  rightHand('右手', 'right_hand'),
  hip('胯部', 'hip'),
  leftKnee('左膝盖', 'left_knee'),
  rightKnee('右膝盖', 'right_knee'),
  leftFoot('左脚', 'left_foot'),
  rightFoot('右脚', 'right_foot');

  const BodyPart(this.displayName, this.apiKey);
  final String displayName;
  final String apiKey;
}

class ChoosePartOfBodyScreen extends StatefulWidget {
  const ChoosePartOfBodyScreen({super.key});

  @override
  State<ChoosePartOfBodyScreen> createState() => _ChoosePartOfBodyScreenState();
}

class _ChoosePartOfBodyScreenState extends State<ChoosePartOfBodyScreen> with TickerProviderStateMixin {
  BodyPart? _selectedPart;
  double _rotationX = 0.0;
  double _rotationY = 0.0;
  double _scale = 1.0;
  AnimationController? _animationController;
  AnimationController? _bounceController;

  // 拖动相关变量
  double _previousRotationY = 0.0;
  double _previousRotationX = 0.0;
  Offset? _lastPanPosition;

  // 缩放相关变量
  double _previousScale = 1.0;

  // 3D部位坐标 - 调整位置使其更准确
  final Map<BodyPart, vector.Vector3> _partPositions = {
    // 头部和颈部
    BodyPart.head: vector.Vector3(0.0, 1.8, 0.0),
    BodyPart.neck: vector.Vector3(0.0, 1.4, 0.0),

    // 肩部和手臂
    BodyPart.leftShoulder: vector.Vector3(-0.6, 1.3, 0.0),
    BodyPart.rightShoulder: vector.Vector3(0.6, 1.3, 0.0),
    BodyPart.leftElbow: vector.Vector3(-1.0, 1.0, 0.1),
    BodyPart.rightElbow: vector.Vector3(1.0, 1.0, 0.1),
    BodyPart.leftHand: vector.Vector3(-1.2, 0.7, 0.2),
    BodyPart.rightHand: vector.Vector3(1.2, 0.7, 0.2),

    // 躯干
    BodyPart.chest: vector.Vector3(0.0, 1.1, 0.0),
    BodyPart.waist: vector.Vector3(0.0, 0.7, 0.0),
    BodyPart.hip: vector.Vector3(0.0, 0.3, 0.0),

    // 腿部和脚
    BodyPart.leftKnee: vector.Vector3(-0.3, 0.0, 0.1),
    BodyPart.rightKnee: vector.Vector3(0.3, 0.0, 0.1),
    BodyPart.leftFoot: vector.Vector3(-0.3, -0.4, 0.2),
    BodyPart.rightFoot: vector.Vector3(0.3, -0.4, 0.2),
  };

  @override
  void initState() {
    super.initState();
    _initAnimationControllers();
  }

  void _initAnimationControllers() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _bounceController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择运动部位'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _build3DViewer(),
          ),
          _buildSelectionBar(),
          Expanded(
            flex: 1,
            child: _buildPartGrid(),
          ),
        ],
      ),
    );
  }

  Widget _build3DViewer() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Listener(
        onPointerSignal: (pointerSignal) {
          // 处理鼠标滚轮缩放
          if (pointerSignal is PointerScrollEvent) {
            setState(() {
              _scale = (_scale - pointerSignal.scrollDelta.dy * 0.001).clamp(0.5, 2.0);
            });
          }
        },
        child: GestureDetector(
          // 使用缩放手势处理所有触摸/鼠标事件
          onScaleStart: (details) {
            _previousScale = _scale;
            _previousRotationY = _rotationY;
            _previousRotationX = _rotationX;
          },
          onScaleUpdate: (details) {
            setState(() {
              // 处理缩放
              _scale = (_previousScale * details.scale).clamp(0.5, 2.0);

              // 处理旋转（用于触摸设备的双指旋转）
              if (details.rotation != 0.0) {
                _rotationY = _previousRotationY + details.rotation;
              }

              // 处理拖动（单指或鼠标移动）
              // 使用 focalPointDelta 来获取移动增量
              if (details.pointerCount == 1) {
                _rotationY = _previousRotationY + details.focalPointDelta.dx * 0.008;
                _rotationX = _previousRotationX + details.focalPointDelta.dy * 0.008;
                _rotationX = _rotationX.clamp(-1.2, 1.2);
              }
            });
          },
          // 处理点击选择部位
          onTapUp: (details) {
            _handle3DPartSelection(details);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue[50]!, Colors.blue[100]!, Colors.blue[200]!],
              ),
            ),
            child: Center(
              child: _build3DHumanModel(),
            ),
          ),
        ),
      ),
    );
  }
  Widget _build3DHumanModel() {
    return Container(
      width: 400,
      height: 500,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.blue[50]!.withOpacity(0.8),
            Colors.blue[100]!.withOpacity(0.6),
          ],
        ),
      ),
      child: _build3DPainter(),
    );
  }

  Widget _build3DPainter() {
    if (_animationController == null || _bounceController == null) {
      return CustomPaint(
        painter: _PlushHumanBody3DPainter(
          selectedPart: _selectedPart,
          rotationX: _rotationX,
          rotationY: _rotationY,
          scale: _scale,
          partPositions: _partPositions,
          animationValue: 0.0,
          bounceValue: 0.0,
        ),
        size: const Size(400, 500),
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_animationController!, _bounceController!]),
      builder: (context, child) {
        return CustomPaint(
          painter: _PlushHumanBody3DPainter(
            selectedPart: _selectedPart,
            rotationX: _rotationX,
            rotationY: _rotationY,
            scale: _scale,
            partPositions: _partPositions,
            animationValue: _animationController!.value,
            bounceValue: _bounceController!.value,
          ),
          size: const Size(400, 500),
        );
      },
    );
  }

  void _handle3DPartSelection(TapUpDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    BodyPart? hitPart;
    double minDistance = double.infinity;

    _partPositions.forEach((part, position) {
      final rotatedPos = _rotatePoint(position);
      final screenPos = _projectToScreen(rotatedPos);
      final distance = (screenPos - localPosition).distance;

      // 不同的部位有不同的点击阈值
      double threshold;
      switch (part) {
        case BodyPart.head:
          threshold = 50.0;
          break;
        case BodyPart.chest:
        case BodyPart.waist:
          threshold = 45.0;
          break;
        case BodyPart.leftHand:
        case BodyPart.rightHand:
        case BodyPart.leftFoot:
        case BodyPart.rightFoot:
          threshold = 40.0;
          break;
        default:
          threshold = 35.0;
      }

      if (distance < threshold && distance < minDistance) {
        minDistance = distance;
        hitPart = part;
      }
    });

    if (hitPart != null) {
      setState(() => _selectedPart = hitPart);
      _showPartSelectionDialog(hitPart!);
    }
  }

  vector.Vector3 _rotatePoint(vector.Vector3 point) {
    final matrix = vector.Matrix4.identity();
    matrix.rotateX(_rotationX);
    matrix.rotateY(_rotationY);
    return matrix.transform3(point);
  }

  Offset _projectToScreen(vector.Vector3 point) {
    final focalLength = 350.0;
    final perspective = focalLength / (focalLength + point.z * 40);

    return Offset(
      200 + point.x * 120 * perspective * _scale,
      250 - point.y * 120 * perspective * _scale,
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _selectedPart != null
                  ? '已选中: ${_selectedPart!.displayName}'
                  : '👆 点击或拖动旋转模型，选择部位 (鼠标滚轮可缩放)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: _selectedPart != null ? FontWeight.bold : FontWeight.normal,
                color: _selectedPart != null ? Colors.blue[700] : Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_selectedPart != null)
            Row(
              children: [
                _buildActionButton(
                  label: '取消',
                  color: Colors.grey[300]!,
                  textColor: Colors.grey[800]!,
                  onPressed: _cancelSelection,
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  label: '确定',
                  color: Colors.blue[500]!,
                  textColor: Colors.white,
                  onPressed: _confirmSelection,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label),
    );
  }

  Widget _buildPartGrid() {
    return Container(
      color: Colors.white,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 2.2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: BodyPart.values.length,
        itemBuilder: (context, index) {
          final part = BodyPart.values[index];
          final isSelected = _selectedPart == part;
          return _buildPartButton(part, isSelected);
        },
      ),
    );
  }

  Widget _buildPartButton(BodyPart part, bool isSelected) {
    return ElevatedButton(
      onPressed: () {
        setState(() => _selectedPart = part);
        _showPartSelectionDialog(part);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue[500] : Colors.grey[100],
        foregroundColor: isSelected ? Colors.white : Colors.grey[800],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        elevation: isSelected ? 4 : 1,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      ),
      child: Text(
        part.displayName,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _showPartSelectionDialog(BodyPart part) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '选择 ${part.displayName}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text('您确定要为 ${part.displayName} 选择运动方案吗？'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelSelection();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _confirmSelection();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[500],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _cancelSelection() => setState(() => _selectedPart = null);

  void _confirmSelection() {
    if (_selectedPart != null) {
      final motionData = _generateMotionData(_selectedPart!);
      context.push('/video_player', extra: motionData);
    }
  }

  Map<String, dynamic> _generateMotionData(BodyPart part) {
    switch (part) {
      case BodyPart.head:
      case BodyPart.neck:
        return {
          'motion_name': '🧘 ${part.displayName}舒缓运动',
          'description': '针对${part.displayName}的舒缓放松运动，缓解疲劳',
          'steps': [
            '坐直身体，放松肩膀',
            '缓慢向前后左右四个方向转动${part.displayName}',
            '每个方向保持5秒',
            '重复3-5次',
          ],
        };
      case BodyPart.leftShoulder:
      case BodyPart.rightShoulder:
      case BodyPart.leftElbow:
      case BodyPart.rightElbow:
      case BodyPart.leftHand:
      case BodyPart.rightHand:
        return {
          'motion_name': '💪 ${part.displayName}力量训练',
          'description': '针对${part.displayName}的力量训练，增强肌肉力量',
          'steps': [
            '站立姿势，保持身体稳定',
            '缓慢活动${part.displayName}，感受肌肉发力',
            '每组做10-15次',
            '休息30秒后进行下一组',
          ],
        };
      case BodyPart.chest:
      case BodyPart.waist:
      case BodyPart.hip:
        return {
          'motion_name': '⚡ ${part.displayName}核心训练',
          'description': '针对${part.displayName}的核心训练，改善身体姿态',
          'steps': [
            '平躺姿势，双手放在身体两侧',
            '收紧核心，缓慢抬起${part.displayName}',
            '保持3-5秒后缓慢放下',
            '重复8-12次',
          ],
        };
      case BodyPart.leftKnee:
      case BodyPart.rightKnee:
      case BodyPart.leftFoot:
      case BodyPart.rightFoot:
        return {
          'motion_name': '🏃 ${part.displayName}柔韧性训练',
          'description': '针对${part.displayName}的柔韧性训练，增加关节灵活性',
          'steps': [
            '坐姿或站姿，保持身体稳定',
            '缓慢拉伸${part.displayName}',
            '感受到轻微拉伸感时保持15秒',
            '缓慢放松，重复2-3次',
          ],
        };
    }
  }
}

// 3D毛绒小人绘制器
class _PlushHumanBody3DPainter extends CustomPainter {
  final BodyPart? selectedPart;
  final double rotationX;
  final double rotationY;
  final double scale;
  final Map<BodyPart, vector.Vector3> partPositions;
  final double animationValue;
  final double bounceValue;

  _PlushHumanBody3DPainter({
    required this.selectedPart,
    required this.rotationX,
    required this.rotationY,
    required this.scale,
    required this.partPositions,
    required this.animationValue,
    required this.bounceValue,
  });

  late final Color brown50 = Colors.brown[50]!;
  late final Color brown100 = Colors.brown[100]!;
  late final Color brown200 = Colors.brown[200]!;
  late final Color brown300 = Colors.brown[300]!;
  late final Color brown400 = Colors.brown[400]!;
  late final Color brown500 = Colors.brown[500]!;
  late final Color brown600 = Colors.brown[600]!;
  late final Color brown700 = Colors.brown[700]!;
  late final Color brown800 = Colors.brown[800]!;
  late final Color brown900 = Colors.brown[900]!;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final matrix = vector.Matrix4.identity();
    matrix.rotateX(rotationX);
    matrix.rotateY(rotationY);

    // 绘制柔和的背景光晕
    _drawBackgroundGlow(canvas, center);

    // 绘制3D毛绒人体
    _drawPlushBody3D(canvas, center, matrix);

    // 绘制部位标记
    _drawPartMarkers(canvas, center, matrix);
  }

  void _drawBackgroundGlow(Canvas canvas, Offset center) {
    final glowPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    canvas.drawCircle(center, 200, glowPaint);
  }

  void _drawPlushBody3D(Canvas canvas, Offset center, vector.Matrix4 matrix) {
    // 身体 - 椭圆形 (使用3D变换)
    final bodyPos = _transformPoint(vector.Vector3(0.0, 0.8 + bounceValue * 0.05, 0.0), matrix, center);
    final bodyWidth = 70 * scale;
    final bodyHeight = 100 * scale;

    // 绘制身体阴影
    final bodyShadowPos = _transformPoint(vector.Vector3(0.0, 0.75, 0.2), matrix, center);
    _draw3DOval(canvas, bodyShadowPos, bodyWidth * 1.1, bodyHeight * 0.3,
        Colors.grey.withOpacity(0.2), Colors.grey.withOpacity(0.1));

    // 绘制身体
    _draw3DOval(canvas, bodyPos, bodyWidth, bodyHeight, brown300, brown500);

    // 头部 - 圆形
    final headPos = _transformPoint(vector.Vector3(0.0, 1.9 + bounceValue * 0.03, 0.0), matrix, center);
    _draw3DCircle(canvas, headPos, 35 * scale, brown200, brown400);

    // 耳朵
    final leftEarPos = _transformPoint(vector.Vector3(-0.25, 2.15, 0.0), matrix, center);
    final rightEarPos = _transformPoint(vector.Vector3(0.25, 2.15, 0.0), matrix, center);

    _draw3DCircle(canvas, leftEarPos, 15 * scale, brown200, brown400);
    _draw3DCircle(canvas, rightEarPos, 15 * scale, brown200, brown400);

    // 绘制手臂和腿 (连接到身体)
    _drawLimbWithJoint(canvas, matrix, center);

    // 绘制脸部
    _drawFace(canvas, matrix, center);

    // 肚子上的小口袋
    final pocketPos = _transformPoint(vector.Vector3(0.0, 1.0, 0.1), matrix, center);
    _drawPocket(canvas, pocketPos);
  }

  void _drawLimbWithJoint(Canvas canvas, vector.Matrix4 matrix, Offset center) {
    // 左手臂 - 从肩膀连接到手
    final shoulderLeft = _transformPoint(vector.Vector3(-0.6, 1.3 + bounceValue * 0.05, 0.0), matrix, center);
    final elbowLeft = _transformPoint(vector.Vector3(-1.0, 1.0, 0.1), matrix, center);
    final handLeft = _transformPoint(vector.Vector3(-1.2, 0.7, 0.2), matrix, center);

    _drawPlushLimb3D(canvas, shoulderLeft, elbowLeft, 20 * scale, brown300, brown400);
    _drawPlushLimb3D(canvas, elbowLeft, handLeft, 18 * scale, brown400, brown500);

    // 右手臂
    final shoulderRight = _transformPoint(vector.Vector3(0.6, 1.3 + bounceValue * 0.05, 0.0), matrix, center);
    final elbowRight = _transformPoint(vector.Vector3(1.0, 1.0, 0.1), matrix, center);
    final handRight = _transformPoint(vector.Vector3(1.2, 0.7, 0.2), matrix, center);

    _drawPlushLimb3D(canvas, shoulderRight, elbowRight, 20 * scale, brown300, brown400);
    _drawPlushLimb3D(canvas, elbowRight, handRight, 18 * scale, brown400, brown500);

    // 左腿 - 从髋部连接到脚
    final hipLeft = _transformPoint(vector.Vector3(-0.3, 0.4 + bounceValue * 0.05, 0.0), matrix, center);
    final kneeLeft = _transformPoint(vector.Vector3(-0.3, 0.0, 0.1), matrix, center);
    final footLeft = _transformPoint(vector.Vector3(-0.3, -0.4, 0.2), matrix, center);

    _drawPlushLimb3D(canvas, hipLeft, kneeLeft, 25 * scale, brown400, brown500);
    _drawPlushLimb3D(canvas, kneeLeft, footLeft, 22 * scale, brown500, brown600);

    // 右腿
    final hipRight = _transformPoint(vector.Vector3(0.3, 0.4 + bounceValue * 0.05, 0.0), matrix, center);
    final kneeRight = _transformPoint(vector.Vector3(0.3, 0.0, 0.1), matrix, center);
    final footRight = _transformPoint(vector.Vector3(0.3, -0.4, 0.2), matrix, center);

    _drawPlushLimb3D(canvas, hipRight, kneeRight, 25 * scale, brown400, brown500);
    _drawPlushLimb3D(canvas, kneeRight, footRight, 22 * scale, brown500, brown600);

    // 绘制关节连接点（增强立体感）
    _drawJoint(canvas, shoulderLeft, 8 * scale, brown400);
    _drawJoint(canvas, elbowLeft, 7 * scale, brown500);
    _drawJoint(canvas, handLeft, 9 * scale, brown600);

    _drawJoint(canvas, shoulderRight, 8 * scale, brown400);
    _drawJoint(canvas, elbowRight, 7 * scale, brown500);
    _drawJoint(canvas, handRight, 9 * scale, brown600);

    _drawJoint(canvas, hipLeft, 9 * scale, brown500);
    _drawJoint(canvas, kneeLeft, 8 * scale, brown600);
    _drawJoint(canvas, footLeft, 8 * scale, brown700);

    _drawJoint(canvas, hipRight, 9 * scale, brown500);
    _drawJoint(canvas, kneeRight, 8 * scale, brown600);
    _drawJoint(canvas, footRight, 8 * scale, brown700);
  }

  void _drawJoint(Canvas canvas, Offset position, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawCircle(position, radius, paint);

    // 高光
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    canvas.drawCircle(Offset(position.dx - 2, position.dy - 2), radius * 0.3, highlightPaint);
  }

  void _drawPlushLimb3D(Canvas canvas, Offset start, Offset end, double width, Color color1, Color color2) {
    // 创建渐变色画笔
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        start,
        end,
        [color1, color2],
      )
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, paint);

    // 添加毛绒纹理效果
    final furPaint = Paint()
      ..color = color1.withOpacity(0.3)
      ..strokeWidth = width * 0.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // 在手臂上添加一些毛绒点
    final delta = Offset(end.dx - start.dx, end.dy - start.dy);
    final length = math.sqrt(delta.dx * delta.dx + delta.dy * delta.dy);
    final steps = (length / 10).toInt();

    for (int i = 1; i < steps; i++) {
      final t = i / steps;
      final point = Offset(
        start.dx + delta.dx * t,
        start.dy + delta.dy * t,
      );
      canvas.drawCircle(point, width * 0.15, furPaint);
    }
  }

  void _draw3DCircle(Canvas canvas, Offset center, double radius, Color lightColor, Color darkColor) {
    // 绘制3D球体效果
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(center.dx - radius * 0.2, center.dy - radius * 0.2),
        radius * 1.2,
        [lightColor, darkColor],
      );

    canvas.drawCircle(center, radius, paint);

    // 添加高光
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawCircle(
      Offset(center.dx - radius * 0.2, center.dy - radius * 0.2),
      radius * 0.3,
      highlightPaint,
    );
  }

  void _draw3DOval(Canvas canvas, Offset center, double width, double height, Color lightColor, Color darkColor) {
    final rect = Rect.fromCenter(center: center, width: width, height: height);

    // 创建椭圆形渐变
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(center.dx - width * 0.1, center.dy - height * 0.1),
        width * 0.8,
        [lightColor, darkColor],
      );

    canvas.drawOval(rect, paint);

    // 添加高光
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final highlightRect = Rect.fromCenter(
      center: Offset(center.dx - width * 0.1, center.dy - height * 0.1),
      width: width * 0.3,
      height: height * 0.2,
    );
    canvas.drawOval(highlightRect, highlightPaint);
  }

  void _drawFace(Canvas canvas, vector.Matrix4 matrix, Offset center) {
    final headPos = _transformPoint(vector.Vector3(0.0, 1.9, 0.0), matrix, center);

    // 眼睛
    final leftEyePos = _transformPoint(vector.Vector3(-0.2, 1.95, 0.1), matrix, center);
    final rightEyePos = _transformPoint(vector.Vector3(0.2, 1.95, 0.1), matrix, center);

    // 眼睛白色部分
    canvas.drawCircle(leftEyePos, 6 * scale, Paint()..color = Colors.white);
    canvas.drawCircle(rightEyePos, 6 * scale, Paint()..color = Colors.white);

    // 瞳孔（会随着动画微微移动）
    final eyeOffset = math.sin(animationValue * 2 * math.pi) * 2;
    canvas.drawCircle(
      Offset(leftEyePos.dx - 1 + eyeOffset, leftEyePos.dy - 1),
      3 * scale,
      Paint()..color = brown900,
    );
    canvas.drawCircle(
      Offset(rightEyePos.dx + 1 - eyeOffset, rightEyePos.dy - 1),
      3 * scale,
      Paint()..color = brown900,
    );

    // 眼睛高光
    canvas.drawCircle(
      Offset(leftEyePos.dx - 2, leftEyePos.dy - 2),
      1.5 * scale,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(rightEyePos.dx, rightEyePos.dy - 2),
      1.5 * scale,
      Paint()..color = Colors.white,
    );

    // 腮红
    final blushPaint = Paint()
      ..color = Colors.pink.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(
      Offset(leftEyePos.dx - 15, leftEyePos.dy + 5),
      8 * scale,
      blushPaint,
    );
    canvas.drawCircle(
      Offset(rightEyePos.dx + 15, rightEyePos.dy + 5),
      8 * scale,
      blushPaint,
    );

    // 微笑的嘴巴
    final mouthPaint = Paint()
      ..color = brown900
      ..strokeWidth = 2 * scale
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(headPos.dx - 10, headPos.dy + 8);
    path.quadraticBezierTo(
      headPos.dx,
      headPos.dy + 15,
      headPos.dx + 10,
      headPos.dy + 8,
    );
    canvas.drawPath(path, mouthPaint);
  }

  void _drawPocket(Canvas canvas, Offset center) {
    final pocketPaint = Paint()
      ..color = brown600.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final pocketStroke = Paint()
      ..color = brown800
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromCenter(center: center, width: 25 * scale, height: 20 * scale);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(8 * scale)),
      pocketPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(8 * scale)),
      pocketStroke,
    );

    // 口袋上的小纽扣
    canvas.drawCircle(
      Offset(center.dx, center.dy - 3),
      3 * scale,
      Paint()..color = brown800,
    );
  }

  void _drawPartMarkers(Canvas canvas, Offset center, vector.Matrix4 matrix) {
    partPositions.forEach((part, position) {
      final screenPos = _transformPoint(position, matrix, center);

      if (part == selectedPart) {
        final pulseSize = 15 + animationValue * 8;

        // 发光效果
        final glowPaint = Paint()
          ..color = Colors.orange.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawCircle(screenPos, pulseSize + 2, glowPaint);

        // 外圈
        canvas.drawCircle(
          screenPos,
          pulseSize,
          Paint()
            ..color = Colors.orange
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );

        // 内圈
        canvas.drawCircle(
          screenPos,
          pulseSize - 4,
          Paint()..color = Colors.orange.withOpacity(0.2),
        );

        // 中心点
        canvas.drawCircle(
          screenPos,
          4 * scale,
          Paint()..color = Colors.white,
        );

        _drawCuteLabel(canvas, screenPos, part.displayName, true);
      } else {
        // 普通部位标记
        canvas.drawCircle(
          screenPos,
          4 * scale,
          Paint()..color = Colors.white.withOpacity(0.8),
        );

        canvas.drawCircle(
          screenPos,
          4 * scale,
          Paint()
            ..color = Colors.blue.withOpacity(0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );

        _drawCuteLabel(canvas, screenPos, part.displayName, false);
      }
    });
  }

  void _drawCuteLabel(Canvas canvas, Offset position, String text, bool isSelected) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: isSelected ? '✨ $text ✨' : text,
        style: TextStyle(
          color: isSelected ? Colors.orange : brown700,
          fontSize: isSelected ? 14 : 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          backgroundColor: isSelected
              ? Colors.white.withOpacity(0.9)
              : Colors.white.withOpacity(0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final rect = Rect.fromCenter(
      center: Offset(position.dx, position.dy - 25),
      width: textPainter.width + 12,
      height: textPainter.height + 6,
    );

    final bgPaint = Paint()
      ..color = isSelected
          ? Colors.white.withOpacity(0.95)
          : Colors.white.withOpacity(0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      bgPaint,
    );

    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy - 28),
    );
  }

  Offset _transformPoint(vector.Vector3 point, vector.Matrix4 matrix, Offset center) {
    final transformed = matrix.transform3(point);

    // 透视投影
    final focalLength = 350.0;
    final perspective = focalLength / (focalLength + transformed.z * 40);

    return Offset(
      center.dx + transformed.x * 120 * perspective * scale,
      center.dy - transformed.y * 120 * perspective * scale,
    );
  }

  @override
  bool shouldRepaint(covariant _PlushHumanBody3DPainter oldDelegate) {
    return oldDelegate.selectedPart != selectedPart ||
        oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.scale != scale ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.bounceValue != bounceValue;
  }
}