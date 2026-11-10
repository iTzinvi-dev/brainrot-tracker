import 'package:flutter_test/flutter_test.dart';
import 'package:brainrot_tracker_pro/features/tracking/domain/scroll_event.dart';
import 'package:brainrot_tracker_pro/features/tracking/domain/platform_type.dart';

void main() {
  group('Tier 1: ScrollEvent Model & Serialization', () {
    test('1. Default instantiation sets expected optional fields', () {
      const event = ScrollEvent(
        sessionId: 'session_test_1',
        platform: PlatformType.instagram,
        timestamp: 1731170000000,
        pageIndex: 5,
      );

      expect(event.id, isNull);
      expect(event.sessionId, equals('session_test_1'));
      expect(event.platform, equals(PlatformType.instagram));
      expect(event.timestamp, equals(1731170000000));
      expect(event.pageIndex, equals(5));
      expect(event.durationMs, equals(0));
      expect(event.isRapidScroll, isFalse);
    });

    test('2. toMap() correctly maps domain fields to SQLite column names', () {
      const event = ScrollEvent(
        id: 42,
        sessionId: 'session_yt_99',
        platform: PlatformType.youtube,
        timestamp: 1731170001000,
        pageIndex: 12,
        durationMs: 4500,
        isRapidScroll: true,
      );

      final map = event.toMap();
      expect(map['session_id'], equals('session_yt_99'));
      expect(map['platform'], equals('youtube'));
      expect(map['timestamp'], equals(1731170001000));
      expect(map['page_index'], equals(12));
      expect(map['duration_ms'], equals(4500));
      expect(map['is_rapid_scroll'], equals(1), reason: 'true must map to 1 for SQLite');
    });

    test('3. fromMap() reconstructs exact ScrollEvent with isRapidScroll true', () {
      final map = {
        'id': 101,
        'session_id': 'session_tiktok_01',
        'platform': 'tiktok',
        'timestamp': 1731170002000,
        'page_index': 7,
        'duration_ms': 1200,
        'is_rapid_scroll': 1,
      };

      final event = ScrollEvent.fromMap(map);
      expect(event.id, equals(101));
      expect(event.sessionId, equals('session_tiktok_01'));
      expect(event.platform, equals(PlatformType.tiktok));
      expect(event.timestamp, equals(1731170002000));
      expect(event.pageIndex, equals(7));
      expect(event.durationMs, equals(1200));
      expect(event.isRapidScroll, isTrue);
    });

    test('4. fromMap() handles isRapidScroll false and 0 duration default', () {
      final map = {
        'id': 202,
        'session_id': 'session_insta_02',
        'platform': 'instagram',
        'timestamp': 1731170003000,
        'page_index': 0,
        'is_rapid_scroll': 0,
      };

      final event = ScrollEvent.fromMap(map);
      expect(event.id, equals(202));
      expect(event.platform, equals(PlatformType.instagram));
      expect(event.durationMs, equals(0));
      expect(event.isRapidScroll, isFalse);
    });

    test('5. Round-trip serialization preserves model integrity across all platforms', () {
      for (final platform in PlatformType.values) {
        final original = ScrollEvent(
          sessionId: 'roundtrip_${platform.name}',
          platform: platform,
          timestamp: 1731170004000,
          pageIndex: 19,
          durationMs: 3200,
          isRapidScroll: false,
        );

        final map = original.toMap();
        final reconstructed = ScrollEvent.fromMap(map);

        expect(reconstructed.sessionId, equals(original.sessionId));
        expect(reconstructed.platform, equals(original.platform));
        expect(reconstructed.timestamp, equals(original.timestamp));
        expect(reconstructed.pageIndex, equals(original.pageIndex));
        expect(reconstructed.durationMs, equals(original.durationMs));
        expect(reconstructed.isRapidScroll, equals(original.isRapidScroll));
      }
    });

    test('6. Null id handling during serialization for auto-increment compatibility', () {
      const event = ScrollEvent(
        sessionId: 'new_event',
        platform: PlatformType.tiktok,
        timestamp: 1731170005000,
        pageIndex: 1,
      );

      final map = event.toMap();
      expect(map.containsKey('id'), isFalse, reason: 'Insert map must omit null id so SQLite auto-increments');
    });
  });
}
