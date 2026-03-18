import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../constants/body_part_catalog.dart';
import '../services/body_part_message_bridge.dart';

class ChoosePartOfBodyScreen extends StatefulWidget {
  const ChoosePartOfBodyScreen({super.key});

  @override
  State<ChoosePartOfBodyScreen> createState() => _ChoosePartOfBodyScreenState();
}

class _ChoosePartOfBodyScreenState extends State<ChoosePartOfBodyScreen> {
  static const String _bodyPartMessagePrefix = 'body-part-selection:';
  static const String _debugMessagePrefix = '__debug__:';
  BodyPartOption? _selectedPart;
  Object? _bodyPartMessageListener;

  static const String _hotspotCss = '''
.body-hotspot {
  width: 18px;
  height: 18px;
  border: 2px solid rgba(255, 255, 255, 0.95);
  border-radius: 50%;
  background: radial-gradient(circle at 35% 35%, #90caf9 0%, #1e88e5 100%);
  box-shadow: 0 0 0 3px rgba(30, 136, 229, 0.25), 0 0 18px rgba(13, 71, 161, 0.55);
  cursor: pointer;
  transition: transform 0.15s ease;
}

.body-hotspot:hover {
  transform: scale(1.2);
}

.body-hotspot-annotation {
  transform: translate(14px, -8px);
  display: inline-block;
  padding: 2px 7px;
  border-radius: 10px;
  background: rgba(15, 23, 42, 0.78);
  color: #e2e8f0;
  font-size: 10px;
  white-space: nowrap;
  pointer-events: none;
}

model-viewer#body-model-viewer {
  filter: saturate(1.08) hue-rotate(14deg) brightness(1.02);
}
''';

  static String get _hotspotJs => '''
(() => {
  const viewer = document.querySelector('model-viewer#body-model-viewer');
  if (!viewer || viewer.dataset.bodyPickBound === '1') return;
  viewer.dataset.bodyPickBound = '1';

  const bridge = window.BodyPartBridge;
  const postToFlutterWindow = (payload) => {
    const targets = [window, window.parent, window.top];
    const posted = new Set();
    targets.forEach((target) => {
      if (!target || posted.has(target) || typeof target.postMessage !== 'function') {
        return;
      }
      try {
        target.postMessage(payload, '*');
        posted.add(target);
      } catch (_) {
      }
    });
  };
  const debug = (message) => {
    const text = String(message || '');
    if (typeof console !== 'undefined' && typeof console.log === 'function') {
      console.log('[BodyHotspot] ' + text);
    }
    postToFlutterWindow('__debug__:' + text);
    if (bridge && typeof bridge.postMessage === 'function') {
      bridge.postMessage('__debug__:' + text);
    }
  };
  debug('hotspot script mounted; bridge=' + (bridge ? 'ready' : 'missing') + '; inIframe=' + (window !== window.top));

  const parsePoint = (raw) => {
    if (!raw || typeof raw !== 'string') return null;
    const values = raw
      .trim()
      .split(/\\s+/)
      .map((part) => Number(part.replace('m', '')));
    if (values.length !== 3 || values.some((value) => Number.isNaN(value))) {
      return null;
    }
    return values;
  };

  const parsePaths = (raw) => {
    if (!raw || typeof raw !== 'string') return [];
    return raw
      .split('|')
      .map((path) => path
        .split(';')
        .map((point) => parsePoint(point))
        .filter((point) => Array.isArray(point) && point.length === 3))
      .filter((path) => path.length > 0);
  };

  const toVector = (value) => {
    if (!value) return null;
    if (typeof value === 'string') return parsePoint(value);
    if (typeof value.x === 'number' && typeof value.y === 'number' && typeof value.z === 'number') {
      return [value.x, value.y, value.z];
    }
    if (typeof value.toString === 'function') {
      return parsePoint(value.toString());
    }
    return null;
  };

  const postPart = (partId) => {
    if (!partId) return;
    debug('postPart -> ' + partId);
    postToFlutterWindow('body-part-selection:' + partId);
    if (bridge && typeof bridge.postMessage === 'function') {
      bridge.postMessage(partId);
    }
  };

  const bindHotspotClicks = () => {
    Array.from(viewer.querySelectorAll('.body-hotspot')).forEach((hotspot) => {
      if (hotspot.dataset.bodyHotspotBound === '1') {
        return;
      }
      hotspot.dataset.bodyHotspotBound = '1';

      hotspot.addEventListener('click', (event) => {
        event.preventDefault();
        event.stopPropagation();
        debug('hotspot click: ' + (hotspot.getAttribute('data-part-id') || ''));
        postPart(hotspot.getAttribute('data-part-id') || '');
      });

      hotspot.addEventListener('pointerdown', (event) => {
        event.stopPropagation();
      });
    });
  };

  const hotspotAnchors = () => Array.from(viewer.querySelectorAll('.body-hotspot'))
    .map((hotspot) => ({
      id: hotspot.getAttribute('data-part-id') || '',
      pos: parsePoint(hotspot.getAttribute('data-position') || ''),
      paths: parsePaths(hotspot.getAttribute('data-paths') || ''),
      radius: Number(hotspot.getAttribute('data-radius') || '0'),
    }))
    .filter((anchor) => anchor.id && anchor.pos);

  const distanceSquared = (a, b) => {
    const dx = a[0] - b[0];
    const dy = a[1] - b[1];
    const dz = a[2] - b[2];
    return (dx * dx) + (dy * dy) + (dz * dz);
  };

  const segmentDistanceSquared = (point, start, end) => {
    const ab = [end[0] - start[0], end[1] - start[1], end[2] - start[2]];
    const ap = [point[0] - start[0], point[1] - start[1], point[2] - start[2]];
    const lengthSquared = (ab[0] * ab[0]) + (ab[1] * ab[1]) + (ab[2] * ab[2]);
    if (lengthSquared <= 1e-8) {
      return distanceSquared(point, start);
    }

    const projection = ((ap[0] * ab[0]) + (ap[1] * ab[1]) + (ap[2] * ab[2])) / lengthSquared;
    const clamped = Math.max(0, Math.min(1, projection));
    const closest = [
      start[0] + (ab[0] * clamped),
      start[1] + (ab[1] * clamped),
      start[2] + (ab[2] * clamped),
    ];
    return distanceSquared(point, closest);
  };

  const pathDistanceSquared = (point, path) => {
    if (!Array.isArray(path) || path.length === 0) {
      return Number.POSITIVE_INFINITY;
    }
    if (path.length === 1) {
      return distanceSquared(point, path[0]);
    }

    let best = Number.POSITIVE_INFINITY;
    for (let index = 1; index < path.length; index += 1) {
      const current = segmentDistanceSquared(point, path[index - 1], path[index]);
      if (current < best) {
        best = current;
      }
    }
    return best;
  };

  const nearestPartId = (pickedPos) => {
    const anchors = hotspotAnchors();
    if (!anchors.length || !pickedPos) return '';

    let nearestId = '';
    let nearestScore = Number.POSITIVE_INFINITY;
    for (const anchor of anchors) {
      let bestDistanceSquared = distanceSquared(pickedPos, anchor.pos);
      for (const path of anchor.paths) {
        const current = pathDistanceSquared(pickedPos, path);
        if (current < bestDistanceSquared) {
          bestDistanceSquared = current;
        }
      }

      const radius = Math.max(anchor.radius, 0.001);
      const score = bestDistanceSquared / (radius * radius);
      if (score < nearestScore) {
        nearestScore = score;
        nearestId = anchor.id;
      }
    }

    return nearestScore <= 1.35 ? nearestId : '';
  };

  bindHotspotClicks();
  viewer.addEventListener('load', bindHotspotClicks);
  viewer.addEventListener('load', () => {
    debug('viewer load; hotspot count=' + viewer.querySelectorAll('.body-hotspot').length);
  });

  viewer.addEventListener('click', (event) => {
    const path = typeof event.composedPath === 'function' ? event.composedPath() : [];
    const hotspot = path.find((node) => node && node.classList && node.classList.contains('body-hotspot'));
    if (hotspot) {
      event.preventDefault();
      event.stopPropagation();
      debug('viewer delegated hotspot click: ' + (hotspot.getAttribute('data-part-id') || ''));
      postPart(hotspot.getAttribute('data-part-id') || '');
      return;
    }

    if (typeof viewer.positionAndNormalFromPoint !== 'function') {
      return;
    }

    const picked = viewer.positionAndNormalFromPoint(event.clientX, event.clientY);
    const pickedPos = toVector(picked && picked.position ? picked.position : picked);
    debug('viewer click pick: ' + JSON.stringify(pickedPos));
    if (!pickedPos) {
      return;
    }

    const nearestId = nearestPartId(pickedPos);
    debug('nearestPartId: ' + nearestId);
    postPart(nearestId);
  });
})();
''';
  bool get _supportsReal3D {
    if (kIsWeb) {
      return true;
    }
        return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    debugPrint('[BodyHotspot] initState attach message listener');
    _bodyPartMessageListener = listenToBodyPartMessages(_handlePartSelection);
  }

  @override
  void dispose() {
    cancelBodyPartMessageListener(_bodyPartMessageListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择身体部位'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _supportsReal3D ? _buildModelArea() : _buildFallbackArea(),
            ),
          ),
          _buildSelectionBar(),
          Expanded(
            flex: 2,
            child: _buildPartGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildModelArea() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEAF4FF), Color(0xFFD7E9FF), Color(0xFFC6DFFF)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ModelViewer(
              id: 'body-model-viewer',
              src: 'assets/models/human_body_blue_clean.glb',
              alt: '人体 3D 模型',
              ar: false,
              autoRotate: false,
              cameraControls: true,
              disableTap: false,
              interactionPrompt: InteractionPrompt.none,
              backgroundColor: Colors.transparent,
              minHotspotOpacity: 0.95,
              maxHotspotOpacity: 1.0,
              cameraOrbit: '0deg 78deg 2.3m',
              minCameraOrbit: 'auto 30deg 1.6m',
              maxCameraOrbit: 'auto 105deg 3.2m',
              cameraTarget: '0m 1.0m 0m',
              innerModelViewerHtml: _hotspotSlotsHtml,
              relatedCss: _hotspotCss,
              relatedJs: _hotspotJs,
              javascriptChannels: {
                JavascriptChannel(
                  'BodyPartBridge',
                  onMessageReceived: _onHotspotMessage,
                ),
              },
              debugLogging: false,
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Text(
                '拖动可旋转，点击模型热点可选部位',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blueGrey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onHotspotMessage(dynamic message) {
    String? raw;
    if (message is String) {
      raw = message;
    } else {
      try {
        raw = (message as dynamic).message?.toString();
      } catch (_) {
        raw = message?.toString();
      }
    }
    if (raw == null || raw.isEmpty) {
      return;
    }
    if (raw.startsWith(_debugMessagePrefix)) {
      debugPrint('[BodyHotspot] ${raw.substring(_debugMessagePrefix.length)}');
      return;
    }
    debugPrint('[BodyHotspot] channel message: $raw');
    _handlePartSelection(raw);
  }

  void _handlePartSelection(String id) {
    debugPrint('[BodyHotspot] _handlePartSelection input: $id');
    var normalizedId = id.trim();
    if (normalizedId.startsWith(_bodyPartMessagePrefix)) {
      normalizedId = normalizedId.substring(_bodyPartMessagePrefix.length).trim();
    }
    debugPrint('[BodyHotspot] normalized id: $normalizedId');
    if (normalizedId.isEmpty) {
      debugPrint('[BodyHotspot] normalized id empty, ignore');
      return;
    }

    final option = _findOptionById(normalizedId);
    if (option == null) {
      debugPrint('[BodyHotspot] no option found for id: $normalizedId');
      return;
    }
    debugPrint('[BodyHotspot] selected option: ${option.id}/${option.displayName}');
    setState(() => _selectedPart = option);
  }

  BodyPartOption? _findOptionById(String id) {
    for (final option in BodyPartCatalog.options) {
      if (option.id == id) {
        return option;
      }
    }
    return null;
  }

  static String get _hotspotSlotsHtml {
    final html = StringBuffer();
    for (final option in BodyPartCatalog.options) {
      html
        ..write('<button class="body-hotspot" slot="hotspot-${option.id}" ')
        ..write('type="button" ')
        ..write('data-part-id="${option.id}" ')
        ..write('data-position="${option.hotspotPositionString}" ')
        ..write('data-normal="${option.hotspotNormalString}" ')
        ..write('data-paths="${option.selectionPathsString}" ')
        ..write('data-radius="${option.selectionRadiusString}" ')
        ..write('onpointerdown="$_inlineStopPointerHandler" ')
        ..write('onclick="${_inlineHotspotClickHandler(option.id)}" ')
        ..write('aria-label="${option.displayName}"></button>')
        ..write('<div class="body-hotspot-annotation" slot="hotspot-${option.id}">')
        ..write(option.displayName)
        ..write('</div>');
    }
    return html.toString();
  }

  static const String _inlineStopPointerHandler =
      'event.stopPropagation();';

  static String _inlineHotspotClickHandler(String partId) {
    final message = 'body-part-selection:$partId';
    return 'event.preventDefault();'
        'event.stopPropagation();'
        'try{window.postMessage(\'$message\',\'*\');}catch(_){}'
        'try{if(window.parent&&window.parent!==window){window.parent.postMessage(\'$message\',\'*\');}}catch(_){}'
        'try{if(window.top&&window.top!==window){window.top.postMessage(\'$message\',\'*\');}}catch(_){}'
        'try{if(window.BodyPartBridge&&typeof window.BodyPartBridge.postMessage===\'function\'){window.BodyPartBridge.postMessage(\'$partId\');}}catch(_){}'
        'return false;';
  }

  Widget _buildFallbackArea() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF2F8FF), Color(0xFFE9F2FF)],
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.accessibility_new_rounded, size: 92, color: Colors.blue[500]),
          const SizedBox(height: 12),
          const Text(
            '当前平台使用轻量模式',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '请在下方部位列表中选择目标区域',
            style: TextStyle(fontSize: 13, color: Colors.blueGrey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _selectedPart == null ? '请选择一个身体部位' : '已选择：${_selectedPart!.displayName}',
              style: TextStyle(
                fontWeight: _selectedPart == null ? FontWeight.w400 : FontWeight.w700,
                color: _selectedPart == null ? Colors.grey[700] : Colors.blue[700],
              ),
            ),
          ),
          TextButton(
            onPressed: _selectedPart == null
                ? null
                : () {
                    context.push(
                      '/motion_recommendation',
                      extra: {'bodyPart': _selectedPart!.displayName},
                    );
                  },
            child: const Text('AI 推荐'),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: _selectedPart == null ? null : _goToVideo,
            child: const Text('视频指导'),
          ),
        ],
      ),
    );
  }

  Widget _buildPartGrid() {
    return Container(
      color: Colors.white,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 2.4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: BodyPartCatalog.options.length,
        itemBuilder: (context, index) {
          final part = BodyPartCatalog.options[index];
          final selected = _selectedPart?.id == part.id;
          return OutlinedButton(
            onPressed: () => setState(() => _selectedPart = part),
            style: OutlinedButton.styleFrom(
              backgroundColor: selected ? const Color(0xFFE3F2FD) : Colors.white,
              foregroundColor: selected ? const Color(0xFF0D47A1) : const Color(0xFF455A64),
              side: BorderSide(
                color: selected ? const Color(0xFF1E88E5) : const Color(0xFFCFD8DC),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              part.displayName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    );
  }

  void _goToVideo() {
    final selected = _selectedPart;
    if (selected == null) {
      return;
    }
    context.push('/video_player', extra: {
      'motion_name': '${selected.displayName}放松训练',
      'body_part': selected.videoKeyword,
      'description': '针对${selected.displayName}的舒缓训练，帮助快速放松。',
      'steps': [
        '保持舒适站姿或坐姿，放松呼吸',
        '缓慢活动${selected.displayName}，动作均匀稳定',
        '每组持续 30 秒，重复 2-3 轮',
      ],
    });
  }
}
