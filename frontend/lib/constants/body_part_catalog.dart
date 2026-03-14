class BodyPartOption {
  const BodyPartOption({
    required this.id,
    required this.displayName,
    required this.apiKey,
    required this.recommendationName,
    required this.videoKeyword,
    required this.hotspotPosition,
    required this.hotspotNormal,
  });

  final String id;
  final String displayName;
  final String apiKey;
  final String recommendationName;
  final String videoKeyword;
  final String hotspotPosition;
  final String hotspotNormal;
}

class BodyPartCatalog {
  static const List<BodyPartOption> options = [
    BodyPartOption(
      id: 'head',
      displayName: '头部',
      apiKey: 'head',
      recommendationName: '颈部',
      videoKeyword: '颈部',
      hotspotPosition: '0m 1.72m 0.04m',
      hotspotNormal: '0m 0m 1m',
    ),
    BodyPartOption(
      id: 'neck',
      displayName: '颈部',
      apiKey: 'neck',
      recommendationName: '颈部',
      videoKeyword: '颈部',
      hotspotPosition: '0m 1.52m 0.06m',
      hotspotNormal: '0m 0m 1m',
    ),
    BodyPartOption(
      id: 'leftShoulder',
      displayName: '左肩',
      apiKey: 'left_shoulder',
      recommendationName: '肩部',
      videoKeyword: '肩部',
      hotspotPosition: '-0.24m 1.42m 0.06m',
      hotspotNormal: '0m 0m 1m',
    ),
    BodyPartOption(
      id: 'rightShoulder',
      displayName: '右肩',
      apiKey: 'right_shoulder',
      recommendationName: '肩部',
      videoKeyword: '肩部',
      hotspotPosition: '0.24m 1.42m 0.06m',
      hotspotNormal: '0m 0m 1m',
    ),
    BodyPartOption(
      id: 'chest',
      displayName: '胸背',
      apiKey: 'chest',
      recommendationName: '背部',
      videoKeyword: '背部',
      hotspotPosition: '0m 1.28m 0.08m',
      hotspotNormal: '0m 0m 1m',
    ),
    BodyPartOption(
      id: 'waist',
      displayName: '腰部',
      apiKey: 'waist',
      recommendationName: '腰部',
      videoKeyword: '腰部',
      hotspotPosition: '0m 1.02m 0.08m',
      hotspotNormal: '0m 0m 1m',
    ),
    BodyPartOption(
      id: 'hip',
      displayName: '胯部',
      apiKey: 'hip',
      recommendationName: '腿部',
      videoKeyword: '腿',
      hotspotPosition: '0m 0.86m 0.08m',
      hotspotNormal: '0m 0m 1m',
    ),
    BodyPartOption(
      id: 'leftArm',
      displayName: '左手臂',
      apiKey: 'left_arm',
      recommendationName: '手腕',
      videoKeyword: '手臂',
      hotspotPosition: '-0.56m 1.33m 0.06m',
      hotspotNormal: '0m 0m 1m',
    ),
    BodyPartOption(
      id: 'rightArm',
      displayName: '右手臂',
      apiKey: 'right_arm',
      recommendationName: '手腕',
      videoKeyword: '手臂',
      hotspotPosition: '0.56m 1.33m 0.06m',
      hotspotNormal: '0m 0m 1m',
    ),
    BodyPartOption(
      id: 'leftKnee',
      displayName: '左膝盖',
      apiKey: 'left_knee',
      recommendationName: '腿部',
      videoKeyword: '膝',
      hotspotPosition: '-0.13m 0.55m 0.08m',
      hotspotNormal: '0m 0m 1m',
    ),
    BodyPartOption(
      id: 'rightKnee',
      displayName: '右膝盖',
      apiKey: 'right_knee',
      recommendationName: '腿部',
      videoKeyword: '膝',
      hotspotPosition: '0.13m 0.55m 0.08m',
      hotspotNormal: '0m 0m 1m',
    ),
    BodyPartOption(
      id: 'leftFoot',
      displayName: '左脚踝',
      apiKey: 'left_foot',
      recommendationName: '腿部',
      videoKeyword: '踝',
      hotspotPosition: '-0.10m 0.10m 0.10m',
      hotspotNormal: '0m 0m 1m',
    ),
    BodyPartOption(
      id: 'rightFoot',
      displayName: '右脚踝',
      apiKey: 'right_foot',
      recommendationName: '腿部',
      videoKeyword: '踝',
      hotspotPosition: '0.10m 0.10m 0.10m',
      hotspotNormal: '0m 0m 1m',
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

  static BodyPartOption? findByApiKey(String apiKey) {
    for (final option in options) {
      if (option.apiKey == apiKey) {
        return option;
      }
    }
    return null;
  }
}
