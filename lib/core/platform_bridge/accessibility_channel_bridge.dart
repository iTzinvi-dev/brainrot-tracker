import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brainrot_tracker_pro/core/constants/app_constants.dart';
import 'package:brainrot_tracker_pro/features/tracking/domain/platform_type.dart';
import 'package:brainrot_tracker_pro/features/tracking/domain/scroll_event.dart';
import 'package:brainrot_tracker_pro/features/tracking/presentation/controllers/tracking_controller.dart';
import 'package:brainrot_tracker_pro/features/tracking/presentation/controllers/operational_settings_controller.dart';
import 'package:brainrot_tracker_pro/features/interventions/presentation/controllers/intervention_controller.dart';

/// Bidirectional platform bridge communicating with Android BrainrotAccessibilityService and Overlay.
class AccessibilityChannelBridge {
  static final AccessibilityChannelBridge _instance = AccessibilityChannelBridge._internal();
  factory AccessibilityChannelBridge() => _instance;
  AccessibilityChannelBridge._internal();

  final MethodChannel _methodChannel = const MethodChannel(AppConstants.methodChannelName);
  final EventChannel _eventChannel = const EventChannel(AppConstants.eventChannelName);

  Stream<Map<String, dynamic>>? _eventStream;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  /// Stream of native events (reel_confirmed, session_state, intervention).
  Stream<Map<String, dynamic>> get eventStream {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event as Map));
    return _eventStream!;
  }

  /// Checks if BrainrotAccessibilityService is currently enabled in Android system settings.
  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final bool? enabled = await _methodChannel.invokeMethod<bool>('isAccessibilityServiceEnabled');
      return enabled ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens the Android system Accessibility Settings screen.
  Future<bool> openAccessibilitySettings() async {
    try {
      final bool? result = await _methodChannel.invokeMethod<bool>('openAccessibilitySettings');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Retrieves today's reel count cached by the native service.
  Future<int> getTodayCount() async {
    try {
      final int? count = await _methodChannel.invokeMethod<int>('getTodayCount');
      return count ?? 0;
    } on PlatformException {
      return 0;
    }
  }

  /// Retrieves per-platform reel statistics from the native service.
  Future<Map<String, int>> getPlatformStats() async {
    try {
      final result = await _methodChannel.invokeMapMethod<String, dynamic>('getPlatformStats');
      if (result == null) return {};
      return result.map((k, v) => MapEntry(k, (v as num).toInt()));
    } on PlatformException {
      return {};
    }
  }

  /// Sets the operational CPU mode in the native service (BATTERY_SAVER, BALANCED, PERFORMANCE).
  Future<bool> setOperationalMode(OperationalMode mode) async {
    try {
      final bool? result = await _methodChannel.invokeMethod<bool>(
        'setOperationalMode',
        {'mode': mode.id},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Gets current operational CPU mode from the native service.
  Future<String> getOperationalMode() async {
    try {
      final String? mode = await _methodChannel.invokeMethod<String>('getOperationalMode');
      return mode ?? AppConstants.modeBalanced;
    } on PlatformException {
      return AppConstants.modeBalanced;
    }
  }

  /// Enables or disables banking mode pause in the native service.
  Future<bool> setBankingMode(bool enabled) async {
    try {
      final bool? result = await _methodChannel.invokeMethod<bool>(
        'setBankingMode',
        {'enabled': enabled},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Checks if banking mode is active in the native service.
  Future<bool> isBankingMode() async {
    try {
      final bool? active = await _methodChannel.invokeMethod<bool>('isBankingMode');
      return active ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Resets native reel counters for a new tracking day.
  Future<bool> resetTodayCount() async {
    try {
      final bool? result = await _methodChannel.invokeMethod<bool>('resetTodayCount');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Triggers a native intervention action (e.g. HOME navigation).
  Future<bool> triggerIntervention({String action = 'HOME'}) async {
    try {
      final bool? result = await _methodChannel.invokeMethod<bool>(
        'triggerIntervention',
        {'action': action},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Subscribes to the native EventChannel and synchronizes events into Riverpod notifiers.
  void initializeBridgeListeners(WidgetRef ref) {
    _subscription?.cancel();
    _subscription = eventStream.listen((event) {
      final type = event['type'] as String?;
      if (type == null) return;

      switch (type) {
        case 'reel_confirmed':
          final platformStr = event['platform'] as String? ?? 'instagram';
          final platform = PlatformType.fromPackageName(platformStr);
          final timestamp = (event['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
          final count = (event['count'] as num?)?.toInt() ?? 0;

          final scrollEvent = ScrollEvent(
            sessionId: 'native_session_${DateTime.now().hour}',
            platform: platform,
            timestamp: timestamp,
            pageIndex: count,
          );
          ref.read(trackingProvider.notifier).recordEvent(scrollEvent);
          break;

        case 'session_state':
          final active = event['active'] as bool? ?? false;
          ref.read(trackingProvider.notifier).setTrackingActive(active);
          break;

        case 'intervention':
          final reason = event['reason'] as String? ?? '';
          if (reason == 'velocity_spike') {
            final rate = (event['value'] as num?)?.toDouble() ?? 45.0;
            ref.read(interventionProvider.notifier).triggerVelocityWarning(rate);
          }
          break;
      }
    }, onError: (_) {});
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}

/// Provider for AccessibilityChannelBridge.
final accessibilityBridgeProvider = Provider<AccessibilityChannelBridge>((ref) {
  final bridge = AccessibilityChannelBridge();
  ref.onDispose(() => bridge.dispose());
  return bridge;
});
