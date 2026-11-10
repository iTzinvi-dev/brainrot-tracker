import 'package:brainrot_tracker_pro/features/tracking/domain/platform_type.dart';

/// Aggregated statistics for a specific tracking day.
class DayStats {
  final String dateStr;
  final int totalSwipes;
  final Map<PlatformType, int> platformBreakdown;
  final List<int> hourlyBuckets; // 24 buckets for fl_chart (0..23)
  final int sittingCount; // continuous sessions separated by > 3min gaps
  final int totalDurationMs;
  final double averageDwellSeconds;
  final int rapidSwipesCount;

  const DayStats({
    required this.dateStr,
    required this.totalSwipes,
    required this.platformBreakdown,
    required this.hourlyBuckets,
    this.sittingCount = 0,
    this.totalDurationMs = 0,
    this.averageDwellSeconds = 0.0,
    this.rapidSwipesCount = 0,
  });

  factory DayStats.empty(String dateStr) => DayStats(
    dateStr: dateStr,
    totalSwipes: 0,
    platformBreakdown: {
      PlatformType.instagram: 0,
      PlatformType.youtube: 0,
      PlatformType.tiktok: 0,
    },
    hourlyBuckets: List.filled(24, 0),
  );
}
