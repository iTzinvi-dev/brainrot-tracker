import 'package:sqflite/sqflite.dart';
import 'package:brainrot_tracker_pro/core/database/database_helper.dart';
import 'package:brainrot_tracker_pro/core/database/sqlite_schema.dart';
import 'package:brainrot_tracker_pro/features/tracking/domain/day_stats.dart';
import 'package:brainrot_tracker_pro/features/tracking/domain/platform_type.dart';
import 'package:brainrot_tracker_pro/features/tracking/domain/scroll_event.dart';

/// Event-sourced repository for logging discrete scroll events and calculating
/// high-performance analytical aggregates across platforms.
class EventSourcedTrackingRepository {
  final DatabaseHelper _dbHelper;

  EventSourcedTrackingRepository([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<Database> get _db => _dbHelper.database;

  /// Records an immutable scroll event into SQLite.
  /// Deduplication is guaranteed by the UNIQUE(session_id, platform, page_index, timestamp) constraint.
  Future<int> recordScrollEvent(ScrollEvent event) async {
    final db = await _db;
    return await db.insert(
      SqliteSchema.tableScrollEvents,
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Aggregates swipe count per platform in the specified epoch ms interval.
  Future<Map<PlatformType, int>> getPlatformBreakdown(int startEpochMs, int endEpochMs) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT platform, COUNT(*) as total_swipes
      FROM ${SqliteSchema.tableScrollEvents}
      WHERE timestamp >= ? AND timestamp <= ?
      GROUP BY platform
    ''', [startEpochMs, endEpochMs]);

    final Map<PlatformType, int> counts = {
      PlatformType.instagram: 0,
      PlatformType.youtube: 0,
      PlatformType.tiktok: 0,
    };

    for (final row in result) {
      final name = row['platform'] as String?;
      final count = row['total_swipes'] as int? ?? 0;
      if (name != null) {
        try {
          final platform = PlatformType.values.byName(name);
          counts[platform] = count;
        } catch (_) {}
      }
    }
    return counts;
  }

  /// Calculates 24 hourly buckets (0..23) for histogram rendering in fl_chart.
  Future<List<int>> getHourlyUsage(int startEpochMs, int endEpochMs) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT CAST(strftime('%H', datetime(timestamp / 1000, 'unixepoch', 'localtime')) AS INTEGER) as hour,
             COUNT(*) as swipe_count
      FROM ${SqliteSchema.tableScrollEvents}
      WHERE timestamp >= ? AND timestamp <= ?
      GROUP BY hour
      ORDER BY hour ASC
    ''', [startEpochMs, endEpochMs]);

    final List<int> hourly = List.filled(24, 0);
    for (final row in result) {
      final hour = row['hour'] as int?;
      final count = row['swipe_count'] as int? ?? 0;
      if (hour != null && hour >= 0 && hour < 24) {
        hourly[hour] = count;
      }
    }
    return hourly;
  }

  /// Computes recent scroll velocity (swipes per minute) in trailing sliding window.
  Future<double> calculateRecentVelocity({int trailingSeconds = 60}) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final cutoff = now - (trailingSeconds * 1000);

    final result = await db.rawQuery('''
      SELECT COUNT(*) as recent_swipes
      FROM ${SqliteSchema.tableScrollEvents}
      WHERE timestamp >= ?
    ''', [cutoff]);

    final count = Sqflite.firstIntValue(result) ?? 0;
    if (trailingSeconds <= 0) return 0.0;
    return (count / trailingSeconds) * 60.0;
  }

  /// Retrieves full day statistics with sitting windows (gaps > 3 min start a new sitting).
  Future<DayStats> getDayStats(DateTime date) async {
    final db = await _db;
    final startOfDay = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999).millisecondsSinceEpoch;
    final dateStr = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final breakdown = await getPlatformBreakdown(startOfDay, endOfDay);
    final hourly = await getHourlyUsage(startOfDay, endOfDay);

    final eventsRaw = await db.query(
      SqliteSchema.tableScrollEvents,
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'timestamp ASC',
    );

    final events = eventsRaw.map((m) => ScrollEvent.fromMap(m)).toList();
    final totalSwipes = events.length;
    int rapidCount = 0;
    int totalDuration = 0;
    int sittingCount = events.isEmpty ? 0 : 1;

    const sittingGapMs = 3 * 60 * 1000; // 3 minutes

    for (int i = 0; i < events.length; i++) {
      if (events[i].isRapidScroll) rapidCount++;
      totalDuration += events[i].durationMs;

      if (i > 0) {
        final gap = events[i].timestamp - events[i - 1].timestamp;
        if (gap > sittingGapMs) {
          sittingCount++;
        }
      }
    }

    final double avgDwell = totalSwipes > 0 ? (totalDuration / totalSwipes) / 1000.0 : 0.0;

    return DayStats(
      dateStr: dateStr,
      totalSwipes: totalSwipes,
      platformBreakdown: breakdown,
      hourlyBuckets: hourly,
      sittingCount: sittingCount,
      totalDurationMs: totalDuration,
      averageDwellSeconds: avgDwell,
      rapidSwipesCount: rapidCount,
    );
  }
}
