import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brainrot_tracker_pro/features/tracking/data/event_sourced_tracking_repository.dart';
import 'package:brainrot_tracker_pro/features/tracking/domain/day_stats.dart';
import 'package:brainrot_tracker_pro/features/tracking/domain/scroll_event.dart';
import 'package:brainrot_tracker_pro/features/tracking/presentation/controllers/tracking_controller.dart';
import 'package:brainrot_tracker_pro/features/tracking/presentation/controllers/daily_limit_controller.dart';
import 'package:brainrot_tracker_pro/features/banking/presentation/controllers/banking_mode_controller.dart';
import 'package:brainrot_tracker_pro/features/pet/presentation/controllers/pet_controller.dart';
import 'package:brainrot_tracker_pro/features/tracking/domain/platform_type.dart';

/// In-memory headless fake repository preventing MissingPluginException in Riverpod unit tests.
class FakeTrackingRepository implements EventSourcedTrackingRepository {
  final List<ScrollEvent> _events = [];

  @override
  Future<int> recordScrollEvent(ScrollEvent event) async {
    _events.add(event);
    return _events.length;
  }

  @override
  Future<Map<PlatformType, int>> getPlatformBreakdown(int startEpochMs, int endEpochMs) async {
    final Map<PlatformType, int> counts = {
      PlatformType.instagram: 0,
      PlatformType.youtube: 0,
      PlatformType.tiktok: 0,
    };
    for (final e in _events) {
      if (e.timestamp >= startEpochMs && e.timestamp <= endEpochMs) {
        counts[e.platform] = (counts[e.platform] ?? 0) + 1;
      }
    }
    return counts;
  }

  @override
  Future<List<int>> getHourlyUsage(int startEpochMs, int endEpochMs) async {
    return List.filled(24, 0);
  }

  @override
  Future<double> calculateRecentVelocity({int trailingSeconds = 60}) async {
    return 0.0;
  }

  @override
  Future<DayStats> getDayStats(DateTime date) async {
    final dateStr = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return DayStats.empty(dateStr);
  }
}

void main() {
  group('Tier 1: Riverpod Notifiers & Initial States', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          trackingRepositoryProvider.overrideWithValue(FakeTrackingRepository()),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('1. TrackingNotifier initial state matches defaults', () {
      final state = container.read(trackingProvider);

      expect(state.totalToday, equals(0));
      expect(state.platformCounts[PlatformType.instagram], equals(0));
      expect(state.platformCounts[PlatformType.youtube], equals(0));
      expect(state.platformCounts[PlatformType.tiktok], equals(0));
      expect(state.currentVelocitySwipesPerMin, equals(0.0));
      expect(state.isTrackingActive, isTrue);
      expect(state.isBankingActive, isFalse);
    });

    test('2. PetNotifier initial state matches Stage 0 Fresh', () {
      final petState = container.read(petProvider);

      expect(petState.stageIndex, equals(0));
      expect(petState.stageLabel, equals('Fresh'));
      expect(petState.petHealth, equals(100));
      expect(petState.rotPercentage, equals(0.0));
      expect(petState.isSlimy, isFalse);
      expect(petState.isSmoking, isFalse);
    });

    test('3. DailyLimitNotifier initial state matches target 150', () {
      final limitState = container.read(dailyLimitProvider);

      expect(limitState.targetLimit, equals(150));
      expect(limitState.warningThreshold, equals(120));
      expect(limitState.isWarningTriggered, isFalse);
      expect(limitState.isLimitExceeded, isFalse);
    });

    test('4. BankingModeNotifier initial state is inactive', () {
      final bankingState = container.read(bankingModeProvider);

      expect(bankingState.isBankingActive, isFalse);
      expect(bankingState.sessionId, isNull);
      expect(bankingState.remainingSeconds, equals(0));
    });

    test('5. PetNotifier responds to applyMindfulRecovery bonus', () {
      final notifier = container.read(petProvider.notifier);
      // Give initial swipes
      notifier.updateWithSwipeCount(50);
      expect(container.read(petProvider).stageIndex, equals(3));

      // Apply mindful recovery
      notifier.applyMindfulRecovery(10);
      final updated = container.read(petProvider);
      expect(updated.recoveryBonusPoints, greaterThan(0));
      expect(updated.petHealth, greaterThan(80));
    });

    test('6. BankingModeNotifier activate/deactivate lifecycle transitions', () {
      final notifier = container.read(bankingModeProvider.notifier);

      notifier.activateBanking(durationMinutes: 15);
      expect(container.read(bankingModeProvider).isBankingActive, isTrue);
      expect(container.read(bankingModeProvider).autoResumeMinutes, equals(15));

      notifier.deactivateBanking();
      expect(container.read(bankingModeProvider).isBankingActive, isFalse);
    });
  });

  group('Tier 1: DailyLimit Logic & Thresholds', () {
    test('1. Default DailyLimitState values and 80% warning threshold', () {
      const state = DailyLimitState();

      expect(state.targetLimit, equals(150));
      expect(state.warningThreshold, equals(120), reason: 'Warning threshold is 80% of target limit');
      expect(state.isWarningTriggered, isFalse);
      expect(state.isLimitExceeded, isFalse);
    });

    test('2. Swipes below warning threshold leaves both triggers false', () {
      final notifier = DailyLimitNotifier();
      notifier.evaluateSwipeCount(119);

      expect(notifier.state.isWarningTriggered, isFalse);
      expect(notifier.state.isLimitExceeded, isFalse);
    });

    test('3. Reaching warning threshold (120) triggers warning only', () {
      final notifier = DailyLimitNotifier();
      notifier.evaluateSwipeCount(120);

      expect(notifier.state.isWarningTriggered, isTrue);
      expect(notifier.state.isLimitExceeded, isFalse);

      notifier.evaluateSwipeCount(149);
      expect(notifier.state.isWarningTriggered, isTrue);
      expect(notifier.state.isLimitExceeded, isFalse);
    });

    test('4. Reaching or exceeding target limit triggers limit exceeded', () {
      final notifier = DailyLimitNotifier();
      notifier.evaluateSwipeCount(150);

      expect(notifier.state.isWarningTriggered, isTrue);
      expect(notifier.state.isLimitExceeded, isTrue);

      notifier.evaluateSwipeCount(250);
      expect(notifier.state.isLimitExceeded, isTrue);
    });

    test('5. Custom target limit updates warning threshold proportionally', () {
      final notifier = DailyLimitNotifier();
      notifier.updateLimit(200);

      expect(notifier.state.targetLimit, equals(200));
      expect(notifier.state.warningThreshold, equals(160), reason: '80% of 200 = 160');

      notifier.evaluateSwipeCount(159);
      expect(notifier.state.isWarningTriggered, isFalse);

      notifier.evaluateSwipeCount(160);
      expect(notifier.state.isWarningTriggered, isTrue);
      expect(notifier.state.isLimitExceeded, isFalse);

      notifier.evaluateSwipeCount(200);
      expect(notifier.state.isLimitExceeded, isTrue);
    });

    test('6. Reset for new day restores initial un-triggered state', () {
      final notifier = DailyLimitNotifier();
      notifier.evaluateSwipeCount(180);
      expect(notifier.state.isLimitExceeded, isTrue);

      notifier.resetDaily();
      expect(notifier.state.isWarningTriggered, isFalse);
      expect(notifier.state.isLimitExceeded, isFalse);
      expect(notifier.state.targetLimit, equals(150));
    });
  });
}
