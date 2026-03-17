import 'dart:async';
import 'dart:html' as html;

const String _messagePrefix = 'body-part-selection:';

Object? listenToBodyPartMessages(void Function(String bodyPartId) onMessage) {
  print('[BodyHotspotBridge] web listener attached');
  return html.window.onMessage.listen((event) {
    final data = event.data;
    final raw = data is String ? data : data?.toString();
    if (raw == null || raw.isEmpty) {
      print('[BodyHotspotBridge] onMessage empty payload');
      return;
    }
    if (!raw.startsWith(_messagePrefix)) {
      print('[BodyHotspotBridge] onMessage ignored: $raw');
      return;
    }

    final bodyPartId = raw.substring(_messagePrefix.length);
    if (bodyPartId.isEmpty) {
      print('[BodyHotspotBridge] onMessage empty bodyPartId');
      return;
    }

    print('[BodyHotspotBridge] onMessage accepted: $bodyPartId');
    onMessage(bodyPartId);
  });
}

void cancelBodyPartMessageListener(Object? listener) {
  if (listener is StreamSubscription<html.MessageEvent>) {
    unawaited(listener.cancel());
  }
}
