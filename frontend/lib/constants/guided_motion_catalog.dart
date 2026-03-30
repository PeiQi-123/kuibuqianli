import 'package:flutter/material.dart';

class GuidedMotionDefinition {
  const GuidedMotionDefinition({
    required this.id,
    required this.title,
    required this.aliases,
    required this.defaultSeconds,
    required this.shortInstruction,
    required this.cameraHint,
    required this.accentColor,
  });

  final String id;
  final String title;
  final List<String> aliases;
  final int defaultSeconds;
  final String shortInstruction;
  final String cameraHint;
  final Color accentColor;
}

class GuidedMotionSession {
  const GuidedMotionSession({
    required this.definition,
    required this.originalActionName,
    required this.seconds,
    required this.fromAiAction,
  });

  final GuidedMotionDefinition definition;
  final String originalActionName;
  final int seconds;
  final bool fromAiAction;

  bool get mappedFromAnotherAction =>
      fromAiAction && originalActionName.trim() != definition.title.trim();
}

class GuidedMotionPlan {
  const GuidedMotionPlan({
    required this.sessions,
    required this.unsupportedActions,
    required this.usedFallbackDefaults,
  });

  final List<GuidedMotionSession> sessions;
  final List<String> unsupportedActions;
  final bool usedFallbackDefaults;
}

class GuidedMotionCatalog {
  static const List<GuidedMotionDefinition> definitions = [
    GuidedMotionDefinition(
      id: 'neck_tilt',
      title: '颈部侧向拉伸',
      aliases: ['颈部侧向拉伸', '颈部侧屈拉伸', '颈部侧屈', '侧屈拉伸', '颈部拉伸'],
      defaultSeconds: 30,
      shortInstruction: '头部缓慢向左右肩交替侧屈，动作时肩膀保持放松。',
      cameraHint: '让头部和双肩完整进入画面，便于识别侧屈幅度。',
      accentColor: Color(0xFF0F766E),
    ),
    GuidedMotionDefinition(
      id: 'shrug',
      title: '耸肩放松',
      aliases: ['耸肩放松', '耸肩', '提肩放松', '肩部提拉'],
      defaultSeconds: 20,
      shortInstruction: '双肩同时向上提起，再慢慢放下，做出明显起伏。',
      cameraHint: '让双肩和上臂进入画面，方便识别肩膀起伏。',
      accentColor: Color(0xFFEA580C),
    ),
    GuidedMotionDefinition(
      id: 'shoulder_circle',
      title: '肩部环绕',
      aliases: ['肩部环绕', '肩部绕环', '肩关节环绕', '绕肩', '肩部画圈'],
      defaultSeconds: 20,
      shortInstruction: '双肩向前、向上、向后、向下缓慢画圈，动作连贯。',
      cameraHint: '让双肩、双肘和上半身进入画面，动作尽量慢。',
      accentColor: Color(0xFF2563EB),
    ),
    GuidedMotionDefinition(
      id: 'chest_open',
      title: '扩胸运动',
      aliases: ['扩胸运动', '扩胸', '扩胸拉伸', '肩胛内收', '打开胸腔'],
      defaultSeconds: 20,
      shortInstruction: '双臂向两侧打开，胸口展开，停留后再回位。',
      cameraHint: '尽量让双手、双肘和双肩都出现在画面中。',
      accentColor: Color(0xFF9333EA),
    ),
  ];

  static const List<String> fallbackOrder = [
    'neck_tilt',
    'shrug',
    'shoulder_circle',
    'chest_open',
  ];

  static GuidedMotionDefinition? findByActionName(String actionName) {
    final normalizedName = normalize(actionName);
    for (final definition in definitions) {
      for (final alias in definition.aliases) {
        final normalizedAlias = normalize(alias);
        if (normalizedName.contains(normalizedAlias) ||
            normalizedAlias.contains(normalizedName)) {
          return definition;
        }
      }
    }
    return null;
  }

  static GuidedMotionPlan buildPlan(
    Map<String, dynamic>? motionData, {
    int maxCount = 4,
  }) {
    final actions = (motionData?['actions'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final sessions = <GuidedMotionSession>[];
    final unsupportedActions = <String>[];
    final usedDefinitionIds = <String>{};

    for (final action in actions) {
      final actionName = action['name']?.toString().trim() ?? '';
      if (actionName.isEmpty) continue;
      final definition = findByActionName(actionName);
      if (definition == null) {
        unsupportedActions.add(actionName);
        continue;
      }
      if (!usedDefinitionIds.add(definition.id)) {
        continue;
      }
      sessions.add(
        GuidedMotionSession(
          definition: definition,
          originalActionName: actionName,
          seconds: _resolveSeconds(action['seconds'], definition.defaultSeconds),
          fromAiAction: true,
        ),
      );
      if (sessions.length >= maxCount) {
        break;
      }
    }

    var usedFallbackDefaults = false;
    for (final fallbackId in fallbackOrder) {
      if (sessions.length >= maxCount) {
        break;
      }
      final definition = definitions.firstWhere((item) => item.id == fallbackId);
      if (!usedDefinitionIds.add(definition.id)) {
        continue;
      }
      sessions.add(
        GuidedMotionSession(
          definition: definition,
          originalActionName: definition.title,
          seconds: definition.defaultSeconds,
          fromAiAction: false,
        ),
      );
      usedFallbackDefaults = true;
    }

    return GuidedMotionPlan(
      sessions: sessions,
      unsupportedActions: unsupportedActions,
      usedFallbackDefaults: usedFallbackDefaults,
    );
  }

  static String normalize(String value) {
    return value
        .replaceAll('.mp4', '')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^\u4e00-\u9fa5A-Za-z0-9]'), '')
        .toLowerCase();
  }

  static int _resolveSeconds(dynamic rawValue, int fallback) {
    if (rawValue is int && rawValue > 0) {
      return rawValue.clamp(15, 40);
    }
    final parsed = int.tryParse(rawValue?.toString() ?? '');
    if (parsed == null || parsed <= 0) {
      return fallback;
    }
    return parsed.clamp(15, 40);
  }
}
