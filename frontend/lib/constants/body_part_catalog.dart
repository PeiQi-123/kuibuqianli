class ModelPoint {
  const ModelPoint(this.x, this.y, this.z);

  const ModelPoint.zero() : x = 0, y = 0, z = 0;

  final double x;
  final double y;
  final double z;

  ModelPoint operator +(ModelPoint other) {
    return ModelPoint(x + other.x, y + other.y, z + other.z);
  }

  ModelPoint operator /(double divisor) {
    return ModelPoint(x / divisor, y / divisor, z / divisor);
  }

  ModelPoint translate(ModelPoint offset) {
    return ModelPoint(x + offset.x, y + offset.y, z + offset.z);
  }

  String get metersString => '${_format(x)}m ${_format(y)}m ${_format(z)}m';

  static ModelPoint average(List<ModelPoint> points) {
    if (points.isEmpty) {
      return const ModelPoint.zero();
    }

    ModelPoint total = const ModelPoint.zero();
    for (final point in points) {
      total = total + point;
    }
    return total / points.length.toDouble();
  }

  static String _format(double value) {
    final fixed = value.toStringAsFixed(4);
    return fixed.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
}

class BodyPath {
  const BodyPath(this.points);

  final List<ModelPoint> points;

  String get metersString => points.map((point) => point.metersString).join(';');
}

class BodyPartOption {
  BodyPartOption({
    required this.id,
    required this.displayName,
    required this.apiKey,
    required this.recommendationName,
    required this.videoKeyword,
    required this.anchorPoints,
    required this.selectionPaths,
    required this.selectionRadius,
    this.hotspotOffset = const ModelPoint.zero(),
    this.hotspotNormal = const ModelPoint(0, 0, 1),
  });

  final String id;
  final String displayName;
  final String apiKey;
  final String recommendationName;
  final String videoKeyword;
  final List<ModelPoint> anchorPoints;
  final List<BodyPath> selectionPaths;
  final double selectionRadius;
  final ModelPoint hotspotOffset;
  final ModelPoint hotspotNormal;

  ModelPoint get hotspotPosition => ModelPoint.average(anchorPoints).translate(hotspotOffset);

  String get hotspotPositionString => hotspotPosition.metersString;

  String get hotspotNormalString => hotspotNormal.metersString;

  String get selectionPathsString => selectionPaths.map((path) => path.metersString).join('|');

  String get selectionRadiusString => selectionRadius.toStringAsFixed(3);
}

class BodyPartCatalog {
  static final List<BodyPartOption> options = [
    BodyPartOption(
      id: 'head',
      displayName: '头部',
      apiKey: 'head',
      recommendationName: '颈部',
      videoKeyword: '颈部',
      anchorPoints: [_bone('mixamorig:Head'), _bone('mixamorig:HeadTop_End')],
      hotspotOffset: const ModelPoint(0, 0, 0.08),
      selectionPaths: [
        BodyPath([
          _bone('mixamorig:Neck'),
          _bone('mixamorig:Head'),
          _bone('mixamorig:HeadTop_End'),
        ]),
      ],
      selectionRadius: 0.14,
    ),
    BodyPartOption(
      id: 'neck',
      displayName: '颈部',
      apiKey: 'neck',
      recommendationName: '颈部',
      videoKeyword: '颈部',
      anchorPoints: [_bone('mixamorig:Neck'), _bone('mixamorig:Head')],
      hotspotOffset: const ModelPoint(0, 0, 0.08),
      selectionPaths: [
        BodyPath([
          _bone('mixamorig:Spine2'),
          _bone('mixamorig:Neck'),
          _bone('mixamorig:Head'),
        ]),
      ],
      selectionRadius: 0.095,
    ),
    BodyPartOption(
      id: 'leftShoulder',
      displayName: '左肩',
      apiKey: 'left_shoulder',
      recommendationName: '肩部',
      videoKeyword: '肩部',
      anchorPoints: [_bone('mixamorig:LeftShoulder'), _bone('mixamorig:LeftArm')],
      hotspotOffset: const ModelPoint(0, 0, 0.085),
      selectionPaths: [
        BodyPath([
          _bone('mixamorig:Spine2'),
          _bone('mixamorig:LeftShoulder'),
          _bone('mixamorig:LeftArm'),
        ]),
      ],
      selectionRadius: 0.11,
    ),
    BodyPartOption(
      id: 'rightShoulder',
      displayName: '右肩',
      apiKey: 'right_shoulder',
      recommendationName: '肩部',
      videoKeyword: '肩部',
      anchorPoints: [_bone('mixamorig:RightShoulder'), _bone('mixamorig:RightArm')],
      hotspotOffset: const ModelPoint(0, 0, 0.085),
      selectionPaths: [
        BodyPath([
          _bone('mixamorig:Spine2'),
          _bone('mixamorig:RightShoulder'),
          _bone('mixamorig:RightArm'),
        ]),
      ],
      selectionRadius: 0.11,
    ),
    BodyPartOption(
      id: 'chest',
      displayName: '胸背',
      apiKey: 'chest',
      recommendationName: '背部',
      videoKeyword: '背部',
      anchorPoints: [_bone('mixamorig:Spine1'), _bone('mixamorig:Spine2')],
      hotspotOffset: const ModelPoint(0, 0, 0.12),
      selectionPaths: [
        BodyPath([
          _bone('mixamorig:Spine'),
          _bone('mixamorig:Spine1'),
          _bone('mixamorig:Spine2'),
          _bone('mixamorig:Neck'),
        ]),
      ],
      selectionRadius: 0.19,
    ),
    BodyPartOption(
      id: 'waist',
      displayName: '腰部',
      apiKey: 'waist',
      recommendationName: '腰部',
      videoKeyword: '腰部',
      anchorPoints: [_bone('mixamorig:Hips'), _bone('mixamorig:Spine')],
      hotspotOffset: const ModelPoint(0, 0, 0.12),
      selectionPaths: [
        BodyPath([
          _bone('mixamorig:Hips'),
          _bone('mixamorig:Spine'),
          _bone('mixamorig:Spine1'),
        ]),
      ],
      selectionRadius: 0.16,
    ),
    BodyPartOption(
      id: 'hip',
      displayName: '胯部',
      apiKey: 'hip',
      recommendationName: '腿部',
      videoKeyword: '腿',
      anchorPoints: [_bone('mixamorig:Hips')],
      hotspotOffset: const ModelPoint(0, 0, 0.12),
      selectionPaths: [
        BodyPath([_bone('mixamorig:Hips'), _bone('mixamorig:Spine')]),
        BodyPath([_bone('mixamorig:Hips'), _bone('mixamorig:LeftUpLeg')]),
        BodyPath([_bone('mixamorig:Hips'), _bone('mixamorig:RightUpLeg')]),
      ],
      selectionRadius: 0.15,
    ),
    BodyPartOption(
      id: 'leftArm',
      displayName: '左手臂',
      apiKey: 'left_arm',
      recommendationName: '手腕',
      videoKeyword: '手臂',
      anchorPoints: [_bone('mixamorig:LeftArm'), _bone('mixamorig:LeftForeArm')],
      hotspotOffset: const ModelPoint(0, 0, 0.095),
      selectionPaths: [
        BodyPath([
          _bone('mixamorig:LeftArm'),
          _bone('mixamorig:LeftForeArm'),
          _bone('mixamorig:LeftHand'),
        ]),
      ],
      selectionRadius: 0.13,
    ),
    BodyPartOption(
      id: 'rightArm',
      displayName: '右手臂',
      apiKey: 'right_arm',
      recommendationName: '手腕',
      videoKeyword: '手臂',
      anchorPoints: [_bone('mixamorig:RightArm'), _bone('mixamorig:RightForeArm')],
      hotspotOffset: const ModelPoint(0, 0, 0.095),
      selectionPaths: [
        BodyPath([
          _bone('mixamorig:RightArm'),
          _bone('mixamorig:RightForeArm'),
          _bone('mixamorig:RightHand'),
        ]),
      ],
      selectionRadius: 0.13,
    ),
    BodyPartOption(
      id: 'leftKnee',
      displayName: '左膝盖',
      apiKey: 'left_knee',
      recommendationName: '腿部',
      videoKeyword: '膝',
      anchorPoints: [_bone('mixamorig:LeftLeg')],
      hotspotOffset: const ModelPoint(0, 0, 0.1),
      selectionPaths: [
        BodyPath([
          _bone('mixamorig:LeftUpLeg'),
          _bone('mixamorig:LeftLeg'),
          _bone('mixamorig:LeftFoot'),
        ]),
      ],
      selectionRadius: 0.12,
    ),
    BodyPartOption(
      id: 'rightKnee',
      displayName: '右膝盖',
      apiKey: 'right_knee',
      recommendationName: '腿部',
      videoKeyword: '膝',
      anchorPoints: [_bone('mixamorig:RightLeg')],
      hotspotOffset: const ModelPoint(0, 0, 0.1),
      selectionPaths: [
        BodyPath([
          _bone('mixamorig:RightUpLeg'),
          _bone('mixamorig:RightLeg'),
          _bone('mixamorig:RightFoot'),
        ]),
      ],
      selectionRadius: 0.12,
    ),
    BodyPartOption(
      id: 'leftFoot',
      displayName: '左脚踝',
      apiKey: 'left_foot',
      recommendationName: '腿部',
      videoKeyword: '踝',
      anchorPoints: [_bone('mixamorig:LeftFoot'), _bone('mixamorig:LeftToeBase')],
      hotspotOffset: const ModelPoint(0, 0, 0.065),
      selectionPaths: [
        BodyPath([
          _bone('mixamorig:LeftLeg'),
          _bone('mixamorig:LeftFoot'),
          _bone('mixamorig:LeftToeBase'),
        ]),
      ],
      selectionRadius: 0.11,
    ),
    BodyPartOption(
      id: 'rightFoot',
      displayName: '右脚踝',
      apiKey: 'right_foot',
      recommendationName: '腿部',
      videoKeyword: '踝',
      anchorPoints: [_bone('mixamorig:RightFoot'), _bone('mixamorig:RightToeBase')],
      hotspotOffset: const ModelPoint(0, 0, 0.065),
      selectionPaths: [
        BodyPath([
          _bone('mixamorig:RightLeg'),
          _bone('mixamorig:RightFoot'),
          _bone('mixamorig:RightToeBase'),
        ]),
      ],
      selectionRadius: 0.11,
    ),
  ];

  static const List<String> recommendationBodyParts = [
    '颈部',
    '肩部',
    '腰部',
    '背部',
    '腿部',
    '手腕',
  ];

  static final Map<String, ModelPoint> _bonePositions = {
    'mixamorig:HeadTop_End': const ModelPoint(0, 1.8197, 0.0598),
    'mixamorig:Head': const ModelPoint(0, 1.5993, -0.0152),
    'mixamorig:Neck': const ModelPoint(0, 1.5031, -0.0320),
    'mixamorig:RightShoulder': const ModelPoint(-0.0457, 1.4459, -0.0332),
    'mixamorig:RightArm': const ModelPoint(-0.1516, 1.4406, -0.0555),
    'mixamorig:RightForeArm': const ModelPoint(-0.4300, 1.4406, -0.0555),
    'mixamorig:RightHand': const ModelPoint(-0.7133, 1.4406, -0.0555),
    'mixamorig:LeftShoulder': const ModelPoint(0.0457, 1.4459, -0.0332),
    'mixamorig:LeftArm': const ModelPoint(0.1516, 1.4406, -0.0555),
    'mixamorig:LeftForeArm': const ModelPoint(0.4300, 1.4406, -0.0555),
    'mixamorig:LeftHand': const ModelPoint(0.7133, 1.4406, -0.0555),
    'mixamorig:Spine2': const ModelPoint(0, 1.3357, -0.0116),
    'mixamorig:Spine1': const ModelPoint(0, 1.2435, 0.0022),
    'mixamorig:Spine': const ModelPoint(0, 1.1446, 0.0169),
    'mixamorig:Hips': const ModelPoint(0, 1.0427, 0.0155),
    'mixamorig:RightUpLeg': const ModelPoint(-0.0821, 0.9752, -0.0005),
    'mixamorig:RightLeg': const ModelPoint(-0.0821, 0.5315, 0.0030),
    'mixamorig:RightFoot': const ModelPoint(-0.0821, 0.0873, -0.0274),
    'mixamorig:RightToeBase': const ModelPoint(-0.0821, 0, 0.0797),
    'mixamorig:LeftUpLeg': const ModelPoint(0.0821, 0.9752, -0.0005),
    'mixamorig:LeftLeg': const ModelPoint(0.0821, 0.5315, 0.0030),
    'mixamorig:LeftFoot': const ModelPoint(0.0821, 0.0873, -0.0274),
    'mixamorig:LeftToeBase': const ModelPoint(0.0821, 0, 0.0797),
  };

  static BodyPartOption? findByApiKey(String apiKey) {
    for (final option in options) {
      if (option.apiKey == apiKey) {
        return option;
      }
    }
    return null;
  }

  static ModelPoint _bone(String name) {
    final point = _bonePositions[name];
    if (point == null) {
      throw ArgumentError('Unknown body model bone: $name');
    }
    return point;
  }
}
