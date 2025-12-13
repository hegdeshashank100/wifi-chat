import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Starts a lightweight foreground service (Android) that periodically
/// pings the main isolate to ensure advertising/discovery stay alive.
class BackgroundScanService {
  static final BackgroundScanService instance = BackgroundScanService._();
  BackgroundScanService._();

  bool _initialized = false;
  bool _running = false;
  VoidCallback? _onEnsure;

  Future<void> start({VoidCallback? onEnsure}) async {
    if (!Platform.isAndroid) return; // Background scanning is Android-only

    _onEnsure = onEnsure;

    if (!_initialized) {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'wifi_chat_scan',
          channelName: 'WiFi Chat Background Scanning',
          channelDescription:
              'Keeps nearby device discovery active while the app is in background',
          onlyAlertOnce: true,
          playSound: false,
          showWhen: true,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(15000),
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );
      FlutterForegroundTask.addTaskDataCallback(_handleTaskData);
      _initialized = true;
    }

    if (_running) return;

    await FlutterForegroundTask.startService(
      notificationTitle: 'WiFi Chat is scanning',
      notificationText: 'Scanning nearby devices • You may have new messages',
      callback: startCallback,
    );
    _running = true;
  }

  Future<void> stop() async {
    if (!Platform.isAndroid) return;
    if (!_running) return;
    await FlutterForegroundTask.stopService();
    _running = false;
  }

  void _handleTaskData(Object data) {
    if (data is Map && data['action'] == 'ensure_services') {
      _onEnsure?.call();
    }
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(BackgroundScanTaskHandler());
}

class BackgroundScanTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {
    FlutterForegroundTask.updateService(
      notificationTitle: 'WiFi Chat is scanning',
      notificationText: 'Scanning nearby devices • You may have new messages',
    );
    FlutterForegroundTask.sendDataToMain({'action': 'ensure_services'});
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isCanceled) async {}
}
