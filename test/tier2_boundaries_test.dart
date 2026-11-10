import 'package:flutter_test/flutter_test.dart';
import 'package:brainrot_tracker_pro/features/pet/domain/brain_rot_calculator.dart';
import 'package:brainrot_tracker_pro/features/interventions/domain/velocity_limiter_algorithm.dart';
import 'package:brainrot_tracker_pro/features/tracking/domain/scroll_event.dart';
import 'package:brainrot_tracker_pro/features/tracking/domain/day_stats.dart';
import 'package:brainrot_tracker_pro/features/tracking/domain/feed_settle_detector.dart';
import 'package:brainrot_tracker_pro/features/tracking/domain/platform_type.dart';
import 'package:brainrot_tracker_pro/core/constants/app_constants.dart';
import 'package:brainrot_tracker_pro/features/interventions/presentation/screens/breathe_screen.dart';
import 'package:flutter/material.dart';

void main() {
  group('Tier 2 Boundary 1: Empty Queries, 0 Swipes, and 1000+ Swipes', () {
    test('1. 0 swipes yields exact baseline state', () {
      final state = BrainRotCalculator.computePetState(0);
      expect(state.stageIndex, equals(0));
      expect(state.stageLabel, equals('Fresh'));
      expect(state.rotPercentage, equals(0.0));
      expect(state.petHealth, equals(100));
      expect(state.isSlimy, isFalse);
      expect(state.isSmoking, isFalse);
      expect(state.swipesUntilNextStage, equals(10));
    });

    test('2. Single swipe (1 swipe) preserves stage 0 with minimal rot', () {
      final state = BrainRotCalculator.computePetState(1);
      expect(state.stageIndex, equals(0));
      expect(state.rotPercentage, closeTo(0.4, 0.05)); // 1/250 = 0.4%
      expect(state.petHealth, equals(100)); // rounded from 99.6
      expect(state.swipesUntilNextStage, equals(9));
    });

    test('3. Exact terminal threshold (250 swipes) reaches 100% rot and 0 health', () {
      final state = BrainRotCalculator.computePetState(250);
      expect(state.stageIndex, equals(6));
      expect(state.rotPercentage, equals(100.0));
      expect(state.petHealth, equals(0));
      expect(state.swipesUntilNextStage, isNull);
    });

    test('4. Extreme swipe counts (1,000 swipes) strictly clamped to stage 6 and 100% rot', () {
      final state = BrainRotCalculator.computePetState(1000);
      expect(state.stageIndex, equals(6));
      expect(state.stageLabel, equals('Brain rot'));
      expect(state.rotPercentage, equals(100.0));
      expect(state.petHealth, equals(0));
      expect(state.isSlimy, isTrue);
      expect(state.isSmoking, isTrue);
    });

    test('5. Extreme swipe counts (100,000 swipes) does not overflow or crash', () {
      final state = BrainRotCalculator.computePetState(100000);
      expect(state.stageIndex, equals(6));
      expect(state.rotPercentage, equals(100.0));
      expect(state.petHealth, equals(0));
    });

    test('6. Empty batch handling produces zero delta across statistics', () {
      final emptyStats = DayStats.empty('2026-11-09');
      expect(emptyStats.totalSwipes, equals(0));
      expect(emptyStats.sittingCount, equals(0));
      expect(emptyStats.rapidSwipesCount, equals(0));
      expect(emptyStats.platformBreakdown.values.every((c) => c == 0), isTrue);
    });
  });

  group('Tier 2 Boundary 2: Rapid Stage Crossing', () {
    test('1. Instant jump from 0 to 250 in single batch transitions directly 0 -> 6', () {
      final stateBefore = BrainRotCalculator.computePetState(0);
      expect(stateBefore.stageIndex, equals(0));

      final stateAfter = BrainRotCalculator.computePetState(250);
      expect(stateAfter.stageIndex, equals(6));
      expect(stateAfter.isSlimy, isTrue);
      expect(stateAfter.isSmoking, isTrue);
    });

    test('2. Boundary skip from 24 (Stage 1) to 26 (Stage 2) crosses threshold cleanly', () {
      final state24 = BrainRotCalculator.computePetState(24);
      expect(state24.stageIndex, equals(1));
      expect(state24.stageLabel, equals('Bruised'));

      final state26 = BrainRotCalculator.computePetState(26);
      expect(state26.stageIndex, equals(2));
      expect(state26.stageLabel, equals('Foggy'));
    });

    test('3. Multi-stage skip across 3 thresholds (20 -> 110: Stage 1 to Stage 4)', () {
      final state110 = BrainRotCalculator.computePetState(110);
      expect(state110.stageIndex, equals(4));
      expect(state110.stageLabel, equals('Mushy'));
      expect(state110.isSlimy, isTrue);
      expect(state110.isSmoking, isFalse);
    });

    test('4. Recovery bonus applied at terminal Stage 6 heals pet back to lower stage', () {
      // 250 swipes with +40% mindful recovery bonus (effective: 250 - 40*2.5 = 150 -> Stage 4)
      final recovered = BrainRotCalculator.computePetState(250, recoveryBonus: 40);
      expect(recovered.stageIndex, equals(4));
      expect(recovered.rotPercentage, equals(60.0)); // 100 - 40
      expect(recovered.petHealth, equals(40));
    });

    test('5. Recovery bonus capped at maximum 80% to maintain baseline accountability', () {
      final recovered = BrainRotCalculator.computePetState(250, recoveryBonus: 80);
      expect(recovered.rotPercentage, equals(20.0)); // 100 - 80
      expect(recovered.petHealth, equals(80));
      expect(recovered.stageIndex, lessThanOrEqualTo(2));
    });
  });

  group('Tier 2 Boundary 3: Clock Shifts & Negative Timestamps', () {
    test('1. Future timestamp (clock skew +1 hour) is preserved without crash', () {
      final futureTime = DateTime.now().millisecondsSinceEpoch + 3600000;
      final event = ScrollEvent(
        sessionId: 'future_session',
        platform: PlatformType.instagram,
        timestamp: futureTime,
        pageIndex: 1,
      );

      expect(event.timestamp, equals(futureTime));
      final map = event.toMap();
      expect(ScrollEvent.fromMap(map).timestamp, equals(futureTime));
    });

    test('2. Zero or negative timestamp handled gracefully by model', () {
      const eventZero = ScrollEvent(
        sessionId: 'zero_session',
        platform: PlatformType.youtube,
        timestamp: 0,
        pageIndex: 0,
      );
      expect(eventZero.timestamp, equals(0));

      const eventNeg = ScrollEvent(
        sessionId: 'neg_session',
        platform: PlatformType.tiktok,
        timestamp: -1000,
        pageIndex: 0,
      );
      expect(eventNeg.timestamp, equals(-1000));
    });

    test('3. Out-of-order events handled by sorting timestamps', () {
      final events = [
        const ScrollEvent(sessionId: 's', platform: PlatformType.instagram, timestamp: 300, pageIndex: 3),
        const ScrollEvent(sessionId: 's', platform: PlatformType.instagram, timestamp: 100, pageIndex: 1),
        const ScrollEvent(sessionId: 's', platform: PlatformType.instagram, timestamp: 200, pageIndex: 2),
      ];

      events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      expect(events[0].pageIndex, equals(1));
      expect(events[1].pageIndex, equals(2));
      expect(events[2].pageIndex, equals(3));
    });

    test('4. Midnight millisecond boundary partitioning (23:59:59.999 vs 00:00:00.000)', () {
      final endOfToday = DateTime.utc(2026, 11, 9, 23, 59, 59, 999).millisecondsSinceEpoch;
      final startOfTomorrow = DateTime.utc(2026, 11, 10, 0, 0, 0, 0).millisecondsSinceEpoch;

      expect(startOfTomorrow - endOfToday, equals(1));
      expect(DateTime.fromMillisecondsSinceEpoch(endOfToday, isUtc: true).day, equals(9));
      expect(DateTime.fromMillisecondsSinceEpoch(startOfTomorrow, isUtc: true).day, equals(10));
    });

    test('5. Large epoch ms (year 2038+ safe) does not overflow 64-bit int', () {
      const future2050 = 2524608000000; // Jan 1 2050
      const event = ScrollEvent(
        sessionId: 'y2050',
        platform: PlatformType.instagram,
        timestamp: future2050,
        pageIndex: 10,
      );
      expect(event.timestamp, equals(future2050));
    });
  });

  group('Tier 2 Boundary 4: Velocity Limiter on Exact Threshold Boundaries', () {
    test('1. Exact 40.0 swipes/min boundary rate evaluation', () {
      final limiter = VelocityLimiterAlgorithm(spikeThresholdSpm: 40.0, windowSeconds: 60);
      final base = DateTime(2026, 11, 9, 12, 0, 0).millisecondsSinceEpoch;

      // 40 swipes spaced exactly 1.5 seconds apart = exactly 40 swipes / 60 seconds = 40 spm
      VelocityResult? result;
      for (int i = 0; i < 40; i++) {
        result = limiter.recordSwipe(timestampMs: base + (i * 1500));
      }

      expect(result?.velocitySpm, closeTo(40.0, 0.5));
      expect(limiter.currentVelocitySpm, greaterThanOrEqualTo(39.5));
    });

    test('2. 39.0 swipes/min does NOT trigger velocity spike', () {
      final limiter = VelocityLimiterAlgorithm(spikeThresholdSpm: 40.0, windowSeconds: 60);
      final base = DateTime(2026, 11, 9, 12, 0, 0).millisecondsSinceEpoch;

      // 39 swipes in 60s
      for (int i = 0; i < 39; i++) {
        limiter.recordSwipe(timestampMs: base + (i * 1538));
      }

      expect(limiter.isSpikeDetected, isFalse);
    });

    test('3. 41.0 swipes/min DOES trigger velocity spike', () {
      final limiter = VelocityLimiterAlgorithm(spikeThresholdSpm: 40.0, windowSeconds: 60);
      final base = DateTime(2026, 11, 9, 12, 0, 0).millisecondsSinceEpoch;

      // 41 swipes in 60s
      for (int i = 0; i < 41; i++) {
        limiter.recordSwipe(timestampMs: base + (i * 1450));
      }

      expect(limiter.isSpikeDetected, isTrue);
    });

    test('4. Exact dwell time boundary: 1800ms threshold', () {
      final limiter = VelocityLimiterAlgorithm(rapidDwellMsThreshold: 1800);
      final now = DateTime(2026, 11, 9, 12, 0, 0).millisecondsSinceEpoch;

      final resAbove = limiter.recordSwipe(timestampMs: now, dwellTimeMs: 1801);
      expect(resAbove.isRapidDwell, isFalse);

      final resBelow = limiter.recordSwipe(timestampMs: now + 2000, dwellTimeMs: 1799);
      expect(resBelow.isRapidDwell, isTrue);
    });

    test('5. Zero delta between consecutive events (deltaT = 0) handles division safely', () {
      final limiter = VelocityLimiterAlgorithm();
      final now = DateTime(2026, 11, 9, 12, 0, 0).millisecondsSinceEpoch;

      limiter.recordSwipe(timestampMs: now);
      final resIdentical = limiter.recordSwipe(timestampMs: now);

      expect(resIdentical.velocitySpm.isNaN, isFalse);
      expect(resIdentical.velocitySpm.isInfinite, isFalse);
    });
  });

  group('Tier 2 Boundary 5: Breathe Screen Countdown Timer Lock State', () {
    testWidgets('1. Countdown lock at t = 0 (5s remaining): button is strictly disabled', (tester) async {
      bool resumed = false;
      await tester.pumpWidget(MaterialApp(
        home: BreatheScreen(
          onResume: () => resumed = true,
          onExitToMenu: () {},
        ),
      ));

      expect(find.text('MINDFUL PAUSE'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      final continueButtonFinder = find.widgetWithText(ElevatedButton, 'Pause for 5 s');
      expect(continueButtonFinder, findsOneWidget);

      // Verify button is disabled
      final ElevatedButton button = tester.widget(continueButtonFinder);
      expect(button.onPressed, isNull);

      // Tapping disabled button should not fire callback
      await tester.tap(continueButtonFinder);
      await tester.pump();
      expect(resumed, isFalse);
    });

    testWidgets('2. Mid-countdown lock at t = 4s (1s remaining): button still disabled', (tester) async {
      bool resumed = false;
      await tester.pumpWidget(MaterialApp(
        home: BreatheScreen(
          onResume: () => resumed = true,
          onExitToMenu: () {},
        ),
      ));

      // Advance 4 seconds
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('1'), findsOneWidget);

      final continueButtonFinder = find.widgetWithText(ElevatedButton, 'Pause for 1 s');
      expect(continueButtonFinder, findsOneWidget);

      final ElevatedButton button = tester.widget(continueButtonFinder);
      expect(button.onPressed, isNull);
      expect(resumed, isFalse);
    });

    testWidgets('3. Lock release at t = 5s (0s remaining): button transitions to enabled', (tester) async {
      bool resumed = false;
      await tester.pumpWidget(MaterialApp(
        home: BreatheScreen(
          onResume: () => resumed = true,
          onExitToMenu: () {},
        ),
      ));

      // Advance full 5 seconds
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('✓'), findsOneWidget);

      final continueButtonFinder = find.widgetWithText(ElevatedButton, 'Continue Scrolling');
      expect(continueButtonFinder, findsOneWidget);

      final ElevatedButton button = tester.widget(continueButtonFinder);
      expect(button.onPressed, isNotNull);

      // Now tapping should fire onResume
      await tester.tap(continueButtonFinder);
      await tester.pump();
      expect(resumed, isTrue);
    });

    testWidgets('4. Dopamine Menu exit button is always unlocked during countdown', (tester) async {
      bool exited = false;
      await tester.pumpWidget(MaterialApp(
        home: BreatheScreen(
          onResume: () {},
          onExitToMenu: () => exited = true,
        ),
      ));

      // At t = 0, exit button must be immediately clickable
      final exitFinder = find.text('Open Dopamine Menu (Heal Brain +10%)');
      expect(exitFinder, findsOneWidget);

      await tester.tap(exitFinder);
      await tester.pump();
      expect(exited, isTrue);
    });

    testWidgets('5. Screen disposal before countdown finishes cancels timer safely', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: BreatheScreen(onResume: () {}, onExitToMenu: () {}),
      ));

      // Advance 2 seconds
      await tester.pump(const Duration(seconds: 2));

      // Replace widget with empty container to trigger dispose
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump(const Duration(seconds: 5));
      // Passes if no unhandled timer exception occurs
    });
  });

  group('Tier 2 Boundary 6: Feed Epoch Resets & Key Hashing', () {
    test('1. Key hash algorithm epoch * 100000 + toIndex generates unique identifiers', () {
      final key0_0 = FeedSettleDetector.computeKey(0, 0);
      final key0_1 = FeedSettleDetector.computeKey(0, 1);
      final key1_0 = FeedSettleDetector.computeKey(1, 0);
      final key1_1 = FeedSettleDetector.computeKey(1, 1);

      expect(key0_0, equals(0));
      expect(key0_1, equals(1));
      expect(key1_0, equals(100000));
      expect(key1_1, equals(100001));

      final set = {key0_0, key0_1, key1_0, key1_1};
      expect(set.length, equals(4));
    });

    test('2. Pull-to-refresh signal triggers epoch increment and seen clearance', () {
      final detector = FeedSettleDetector(packageName: 'com.instagram.android');
      for (int i = 0; i <= 3; i++) {
        final accepted = detector.accept(fromIndex: i, toIndex: i, itemCount: 10);
        expect(accepted, isTrue);
      }
      expect(detector.epoch, equals(0));
      expect(detector.seenIndices.length, equals(4));

      // User refreshed feed: itemCount drops to 5 and toIndex resets to 0
      final refreshed = detector.accept(fromIndex: 0, toIndex: 0, itemCount: 5);
      expect(refreshed, isTrue);
      expect(detector.epoch, equals(1));
      expect(detector.seenIndices.length, equals(1));
    });

    test('3. Standard scroll-back does not trigger epoch increment', () {
      final detector = FeedSettleDetector(packageName: 'com.instagram.android');
      for (int i = 0; i <= 3; i++) {
        detector.accept(fromIndex: i, toIndex: i, itemCount: 10);
      }
      expect(detector.epoch, equals(0));

      // User scrolls backwards from index 3 to index 2 (itemCount unchanged)
      final backResult = detector.accept(fromIndex: 2, toIndex: 2, itemCount: 10);
      expect(backResult, isFalse, reason: 'Standard scroll-back must NOT trigger new event');
      expect(detector.epoch, equals(0), reason: 'Standard scroll-back must NOT trigger epoch reload');
      expect(detector.seenIndices.length, equals(4));
    });

    test('4. High epoch number (epoch 500) does not overflow 64-bit Dart int', () {
      final highKey = FeedSettleDetector.computeKey(500, 42);
      expect(highKey, equals(50000042));
    });

    test('5. Duplicate swipe within same epoch detected and ignored', () {
      final detector = FeedSettleDetector(packageName: 'com.instagram.android');
      final firstAccepted = detector.accept(fromIndex: 5, toIndex: 5, itemCount: 10);
      expect(firstAccepted, isTrue);

      final secondAccepted = detector.accept(fromIndex: 5, toIndex: 5, itemCount: 10);
      expect(secondAccepted, isFalse, reason: 'Duplicate key in same epoch must be rejected');
    });
  });
}
