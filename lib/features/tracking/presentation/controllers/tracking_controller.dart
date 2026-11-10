import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brainrot_tracker_pro/features/tracking/data/event_sourced_tracking_repository.dart';
import 'package:brainrot_tracker_pro/features/tracking/domain/day_stats.dart';
import 'package:brainrot_tracker_pro/features/tracking/domain/platform_type.dart';
import 'package:brainrot_tracker_pro/features/tracking/domain/scroll_event.dart';

/// State of tracking feature.
class TrackingState {
  final int totalToday;
  final Map<PlatformType, int> platformCounts;
  final List<int> hourlyBuckets;
  final double currentVelocitySwipesPerMin;
  final bool isTrackingActive;
  final bool isBankingActive;
  final int? lastEventTimestamp;
  final DayStats? dayStats;

  const TrackingState({
    this.totalToday = 0,
    this.platformCounts = const {
      PlatformType.instagram: 0,
      PlatformType.youtube: 0,
      PlatformType.tiktok: 0,
    },
    this.hourlyBuckets = const [],
    this.currentVelocitySwipesPerMin = 0.0,
    this.isTrackingActive = true,
    this.isBankingActive = false,
    this.lastEventTimestamp,
    this.dayStats,
  });

  TrackingState copyWith({
    int? totalToday,
    Map<PlatformType, int>? platformCounts,
    List<int>? hourlyBuckets,
    double? currentVelocitySwipesPerMin,
    bool? isTrackingActive,
    bool? isBankingActive,
    int? lastEventTimestamp,
    DayStats? dayStats,
  }) {
    return TrackingState(
      totalToday: totalToday ?? this.totalToday,
      platformCounts: platformCounts ?? this.platformCounts,
      hourlyBuckets: hourlyBuckets ?? this.hourlyBuckets,
      currentVelocitySwipesPerMin: currentVelocitySwipesPerMin ?? this.currentVelocitySwipesPerMin,
      isTrackingActive: isTrackingActive ?? this.isTrackingActive,
      isBankingActive: isBankingActive ?? this.isBankingActive,
      lastEventTimestamp: lastEventTimestamp ?? this.lastEventTimestamp,
      dayStats: dayStats ?? this.dayStats,
    );
  }
}

/// Provider for EventSourcedTrackingRepository.
final trackingRepositoryProvider = Provider<EventSourcedTrackingRepository>((ref) {
  return EventSourcedTrackingRepository();
});

/// Notifier driving the Tracking feature state.
class TrackingNotifier extends StateNotifier<TrackingState> {
  final EventSourcedTrackingRepository _repo;

  TrackingNotifier(this._repo) : super(const TrackingState()) {
    refreshStats();
  }

  /// Refreshes today's metrics from SQLite.
  Future<void> refreshStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).millisecondsSinceEpoch;

    final breakdown = await _repo.getPlatformBreakdown(startOfDay, endOfDay);
    final hourly = await _repo.getHourlyUsage(startOfDay, endOfDay);
    final velocity = await _repo.calculateRecentVelocity(trailingSeconds: 60);
    final stats = await _repo.getDayStats(now);

    final total = breakdown.values.fold(0, (sum, count) => sum + count);

    state = state.copyWith(
      totalToday: total,
      platformCounts: breakdown,
      hourlyBuckets: hourly,
      currentVelocitySwipesPerMin: velocity,
      lastEventTimestamp: DateTime.now().millisecondsSinceEpoch,
      dayStats: stats,
    );
  }

  /// Records a new scroll event and updates live metrics.
  Future<void> recordEvent(ScrollEvent event) async {
    if (state.isBankingActive || !state.isTrackingActive) {
      return; // Suppress tracking during banking mode or paused state
    }

    await _repo.recordScrollEvent(event);
    await refreshStats();
  }

  /// Sets banking pause state.
  void setBankingState(bool isBanking) {
    state = state.copyWith(isBankingActive: isBanking);
  }

  /// Toggles global tracking active state.
  void setTrackingActive(bool isActive) {
    state = state.copyWith(isTrackingActive: isActive);
  }
}

/// Main tracking provider.
final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  final repo = ref.watch(trackingRepositoryProvider);
  return TrackingNotifier(repo);
});
