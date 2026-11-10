import 'package:flutter_test/flutter_test.dart';
import 'package:brainrot_tracker_pro/features/tracking/domain/platform_type.dart';
import 'package:brainrot_tracker_pro/features/tracking/domain/scroll_event.dart';
import 'package:brainrot_tracker_pro/features/interventions/domain/dopamine_item.dart';

/// Test fixtures and mock data generators for Brainrot Tracker Pro test suite.
class MockData {
  MockData._();

  static const String testSessionId = 'test_session_001';
  static final int baseTimestamp = DateTime(2026, 11, 9, 12, 0, 0).millisecondsSinceEpoch;

  /// Creates a standard ScrollEvent for testing.
  static ScrollEvent createScrollEvent({
    int? id,
    String sessionId = testSessionId,
    PlatformType platform = PlatformType.instagram,
    int? timestamp,
    int pageIndex = 0,
    int durationMs = 3000,
    bool isRapidScroll = false,
  }) {
    return ScrollEvent(
      id: id,
      sessionId: sessionId,
      platform: platform,
      timestamp: timestamp ?? baseTimestamp,
      pageIndex: pageIndex,
      durationMs: durationMs,
      isRapidScroll: isRapidScroll,
    );
  }

  /// Generates a rapid burst of scroll events within a short time window (e.g., 8 seconds).
  static List<ScrollEvent> generateRapidScrollBurst({
    int count = 10,
    int totalWindowMs = 8000,
    PlatformType platform = PlatformType.tiktok,
    int? startTimestamp,
  }) {
    final start = startTimestamp ?? baseTimestamp;
    final interval = totalWindowMs ~/ count;
    return List.generate(count, (index) {
      return ScrollEvent(
        sessionId: testSessionId,
        platform: platform,
        timestamp: start + (index * interval),
        pageIndex: index,
        durationMs: 700,
        isRapidScroll: true,
      );
    });
  }

  /// Generates relaxed, intentional scroll events with healthy dwell times (> 15 seconds).
  static List<ScrollEvent> generateRelaxedScrollEvents({
    int count = 5,
    PlatformType platform = PlatformType.youtube,
    int? startTimestamp,
  }) {
    final start = startTimestamp ?? baseTimestamp;
    const interval = 20000; // 20s per reel
    return List.generate(count, (index) {
      return ScrollEvent(
        sessionId: testSessionId,
        platform: platform,
        timestamp: start + (index * interval),
        pageIndex: index,
        durationMs: 18000,
        isRapidScroll: false,
      );
    });
  }

  /// Generates an hourly distribution of scroll events across 24 hours.
  static List<ScrollEvent> generateHourlyDistributedEvents({
    required Map<int, int> hourToCountMap,
    int? baseDayMs,
  }) {
    final base = baseDayMs ?? DateTime(2026, 11, 9, 0, 0, 0).millisecondsSinceEpoch;
    final List<ScrollEvent> events = [];

    hourToCountMap.forEach((hour, count) {
      final hourStart = base + (hour * 3600 * 1000);
      for (int i = 0; i < count; i++) {
        events.add(ScrollEvent(
          sessionId: 'session_h$hour',
          platform: PlatformType.values[i % PlatformType.values.length],
          timestamp: hourStart + (i * 60000),
          pageIndex: i,
          durationMs: 4000,
        ));
      }
    });

    return events;
  }
}
