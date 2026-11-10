import 'package:flutter_test/flutter_test.dart';
import 'package:brainrot_tracker_pro/features/interventions/domain/velocity_limiter_algorithm.dart';

void main() {
  group('Tier 1: Velocity Limiter Algorithm & Sliding Window', () {
    late VelocityLimiterAlgorithm limiter;

    setUp(() {
      limiter = VelocityLimiterAlgorithm(
        spikeThresholdSpm: 40.0,
        windowSeconds: 60,
        rapidDwellMsThreshold: 1800,
      );
    });

    test('1. Empty history returns 0.0 velocity and no spike', () {
      expect(limiter.currentVelocitySpm, equals(0.0));
      expect(limiter.isSpikeDetected, isFalse);
    });

    test('2. Single swipe records timestamp but does not trigger spike', () {
      final now = DateTime(2026, 11, 9, 12, 0, 0).millisecondsSinceEpoch;
      final result = limiter.recordSwipe(timestampMs: now, dwellTimeMs: 3000);

      expect(result.isSpike, isFalse);
      expect(result.isRapidDwell, isFalse);
      expect(limiter.isSpikeDetected, isFalse);
    });

    test('3. Relaxed swiping (< 40 swipes/min) maintains normal status', () {
      final base = DateTime(2026, 11, 9, 12, 0, 0).millisecondsSinceEpoch;
      // 5 swipes spaced 10 seconds apart (6 swipes/min)
      for (int i = 0; i < 5; i++) {
        final res = limiter.recordSwipe(
          timestampMs: base + (i * 10000),
          dwellTimeMs: 10000,
        );
        expect(res.isSpike, isFalse);
      }

      expect(limiter.currentVelocitySpm, lessThan(40.0));
      expect(limiter.isSpikeDetected, isFalse);
    });

    test('4. Burst swiping (> 40 swipes/min) triggers velocity spike', () {
      final base = DateTime(2026, 11, 9, 12, 0, 0).millisecondsSinceEpoch;
      // 10 swipes within 10 seconds = 60 swipes/min rate
      VelocityResult? lastResult;
      for (int i = 0; i < 10; i++) {
        lastResult = limiter.recordSwipe(
          timestampMs: base + (i * 1000),
          dwellTimeMs: 1000,
        );
      }

      expect(lastResult?.isSpike, isTrue, reason: 'Velocity rate >= 40 spm must flag spike');
      expect(limiter.isSpikeDetected, isTrue);
      expect(limiter.currentVelocitySpm, greaterThanOrEqualTo(40.0));
    });

    test('5. Rapid dwell time (< 1800ms) flags rapid skimming behavior', () {
      final now = DateTime(2026, 11, 9, 12, 0, 0).millisecondsSinceEpoch;
      final result = limiter.recordSwipe(timestampMs: now, dwellTimeMs: 800);

      expect(result.isRapidDwell, isTrue, reason: 'Dwell time < 1800ms indicates rapid skimming');
    });

    test('6. Window eviction removes timestamps outside the active sliding window', () {
      final base = DateTime(2026, 11, 9, 12, 0, 0).millisecondsSinceEpoch;
      // Add old swipes 2 minutes ago
      for (int i = 0; i < 8; i++) {
        limiter.recordSwipe(timestampMs: base - 120000 + (i * 1000));
      }

      // Add a single swipe right now
      limiter.recordSwipe(timestampMs: base);

      // Limiter window is 60s, so the 8 swipes from 2 mins ago should be evicted
      expect(limiter.activeWindowCount, equals(1));
      expect(limiter.isSpikeDetected, isFalse);
    });

    test('7. Reset clears all historical swipes and active flags', () {
      final base = DateTime(2026, 11, 9, 12, 0, 0).millisecondsSinceEpoch;
      for (int i = 0; i < 10; i++) {
        limiter.recordSwipe(timestampMs: base + (i * 1000), dwellTimeMs: 800);
      }
      expect(limiter.isSpikeDetected, isTrue);

      limiter.reset();
      expect(limiter.isSpikeDetected, isFalse);
      expect(limiter.currentVelocitySpm, equals(0.0));
      expect(limiter.activeWindowCount, equals(0));
    });
  });
}
