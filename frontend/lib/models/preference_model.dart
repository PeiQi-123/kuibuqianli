// 运动偏好数据模型
class PreferenceModel {
  final List<String>? bodyParts;
  final String? difficulty;
  final int? duration;
  final List<String>? sportTypes;
  final List<String>? scenes;
  final bool? silentMotion;
  final bool? slowPace;
  final bool? withMusic;
  final bool? withCoach;
  final bool? withWarmUp;
  final bool? withCoolDown;
  final String? otherFeatures;

  PreferenceModel({
    this.bodyParts,
    this.difficulty,
    this.duration,
    this.sportTypes,
    this.scenes,
    this.silentMotion,
    this.slowPace,
    this.withMusic,
    this.withCoach,
    this.withWarmUp,
    this.withCoolDown,
    this.otherFeatures,
  });

  // 从JSON创建PreferenceModel
  factory PreferenceModel.fromJson(Map<String, dynamic> json) {
    return PreferenceModel(
      bodyParts: json['body_parts'] != null ? List<String>.from(json['body_parts']) : null,
      difficulty: json['difficulty'],
      duration: json['duration'],
      sportTypes: json['sport_types'] != null ? List<String>.from(json['sport_types']) : null,
      scenes: json['scenes'] != null ? List<String>.from(json['scenes']) : null,
      silentMotion: json['silent_motion'],
      slowPace: json['slow_pace'],
      withMusic: json['with_music'],
      withCoach: json['with_coach'],
      withWarmUp: json['with_warm_up'],
      withCoolDown: json['with_cool_down'],
      otherFeatures: json['other_features'],
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'body_parts': bodyParts,
      'difficulty': difficulty,
      'duration': duration,
      'sport_types': sportTypes,
      'scenes': scenes,
      'silent_motion': silentMotion,
      'slow_pace': slowPace,
      'with_music': withMusic,
      'with_coach': withCoach,
      'with_warm_up': withWarmUp,
      'with_cool_down': withCoolDown,
      'other_features': otherFeatures,
    };
  }

  // 创建默认偏好（示例数据）
  static PreferenceModel get defaultPreferences {
    return PreferenceModel(
      bodyParts: ['全身', '上肢', '核心', '肩部', '腰部'],
      difficulty: '入门级',
      duration: 20,
      sportTypes: ['静态拉伸', '动态拉伸', '有氧运动', '微力量锻炼', '关节活动'],
      scenes: ['居家', '办公室', '户外', '学校'],
      silentMotion: false,
      slowPace: true,
      withMusic: true,
      withCoach: true,
      withWarmUp: true,
      withCoolDown: true,
      otherFeatures: '偏好有明确计数和节奏的动作，喜欢有进度条显示，需要动作分解演示',
    );
  }

  // 创建空偏好（用于新用户）
  static PreferenceModel get emptyPreferences {
    return PreferenceModel(
      bodyParts: [],
      difficulty: '入门级',
      duration: 15,
      sportTypes: [],
      scenes: [],
      silentMotion: false,
      slowPace: false,
      withMusic: true,
      withCoach: false,
      withWarmUp: true,
      withCoolDown: true,
      otherFeatures: '',
    );
  }

  // 复制并更新部分字段
  PreferenceModel copyWith({
    List<String>? bodyParts,
    String? difficulty,
    int? duration,
    List<String>? sportTypes,
    List<String>? scenes,
    bool? silentMotion,
    bool? slowPace,
    bool? withMusic,
    bool? withCoach,
    bool? withWarmUp,
    bool? withCoolDown,
    String? otherFeatures,
  }) {
    return PreferenceModel(
      bodyParts: bodyParts ?? this.bodyParts,
      difficulty: difficulty ?? this.difficulty,
      duration: duration ?? this.duration,
      sportTypes: sportTypes ?? this.sportTypes,
      scenes: scenes ?? this.scenes,
      silentMotion: silentMotion ?? this.silentMotion,
      slowPace: slowPace ?? this.slowPace,
      withMusic: withMusic ?? this.withMusic,
      withCoach: withCoach ?? this.withCoach,
      withWarmUp: withWarmUp ?? this.withWarmUp,
      withCoolDown: withCoolDown ?? this.withCoolDown,
      otherFeatures: otherFeatures ?? this.otherFeatures,
    );
  }

  @override
  String toString() {
    return '''
PreferenceModel:
  身体部位: ${bodyParts?.join(', ') ?? '未设置'}
  动作难度: $difficulty
  偏好时长: ${duration}分钟
  运动类型: ${sportTypes?.join(', ') ?? '未设置'}
  运动场景: ${scenes?.join(', ') ?? '未设置'}
  静音动作: $silentMotion
  慢节奏: $slowPace
  背景音乐: $withMusic
  教练指导: $withCoach
  包含热身: $withWarmUp
  包含放松: $withCoolDown
  其他特点: $otherFeatures
''';
  }
}
