import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brainrot_tracker_pro/core/database/database_helper.dart';
import 'package:brainrot_tracker_pro/features/tracking/presentation/controllers/tracking_controller.dart';

/// State of daily quota limit and warning thresholds.
class DailyLimitState {
  final int targetLimit;
  final int warningThreshold;
  final bool isWarningTriggered;
  final bool isLimitExceeded;

  const DailyLimitState({
    this.targetLimit = 150,
    this.warningThreshold = 120,
    this.isWarningTriggered = false,
    this.isLimitExceeded = false,
  });

  DailyLimitState copyWith({
    int? targetLimit,
    int? warningThreshold,
    bool? isWarningTriggered,
    bool? isLimitExceeded,
  }) {
    return DailyLimitState(
      targetLimit: targetLimit ?? this.targetLimit,
      warningThreshold: warningThreshold ?? this.warningThreshold,
      isWarningTriggered: isWarningTriggered ?? this.isWarningTriggered,
      isLimitExceeded: isLimitExceeded ?? this.isLimitExceeded,
    );
  }
}

/// Notifier driving daily limit quotas, 80% warning triggers, and daily resets.
class DailyLimitNotifier extends StateNotifier<DailyLimitState> {
  final DatabaseHelper _dbHelper;

  DailyLimitNotifier([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper(),
        super(const DailyLimitState());

  /// Evaluates current swipe count against target and warning thresholds.
  void evaluateSwipeCount(int currentSwipeCount) {
    final isExceeded = currentSwipeCount >= state.targetLimit;
    final isWarning = isExceeded || (currentSwipeCount >= state.warningThreshold);

    state = state.copyWith(
      isWarningTriggered: isWarning,
      isLimitExceeded: isExceeded,
    );
  }

  /// Sets a custom target limit and proportionally recalculates the 80% warning threshold.
  void updateLimit(int newLimit) {
    final newWarning = (newLimit * 0.8).round();
    state = state.copyWith(
      targetLimit: newLimit,
      warningThreshold: newWarning,
    );
  }

  /// Resets daily triggers and restores the default limit configuration.
  void resetDaily() {
    state = const DailyLimitState(
      targetLimit: 150,
      warningThreshold: 120,
      isWarningTriggered: false,
      isLimitExceeded: false,
    );
  }
}

/// Riverpod provider for daily limit state, automatically synced with tracking updates.
final dailyLimitProvider =
    StateNotifierProvider<DailyLimitNotifier, DailyLimitState>((ref) {
  final notifier = DailyLimitNotifier();
  ref.listen<TrackingState>(trackingProvider, (prev, next) {
    if (prev?.totalToday != next.totalToday) {
      notifier.evaluateSwipeCount(next.totalToday);
    }
  });
  return notifier;
});
