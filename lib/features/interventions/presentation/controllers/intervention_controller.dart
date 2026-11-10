import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brainrot_tracker_pro/core/database/database_helper.dart';
import 'package:brainrot_tracker_pro/core/database/sqlite_schema.dart';

/// State of anti-doomscroll interventions.
class InterventionState {
  final bool isVelocityWarningVisible;
  final double currentVelocity;
  final int completedInterventionsCount;
  final String? activeInterventionType;

  const InterventionState({
    this.isVelocityWarningVisible = false,
    this.currentVelocity = 0.0,
    this.completedInterventionsCount = 0,
    this.activeInterventionType,
  });

  InterventionState copyWith({
    bool? isVelocityWarningVisible,
    double? currentVelocity,
    int? completedInterventionsCount,
    String? activeInterventionType,
  }) {
    return InterventionState(
      isVelocityWarningVisible: isVelocityWarningVisible ?? this.isVelocityWarningVisible,
      currentVelocity: currentVelocity ?? this.currentVelocity,
      completedInterventionsCount: completedInterventionsCount ?? this.completedInterventionsCount,
      activeInterventionType: activeInterventionType ?? this.activeInterventionType,
    );
  }
}

/// Notifier coordinating mindfulness interventions and logging audit events to SQLite.
class InterventionNotifier extends StateNotifier<InterventionState> {
  final DatabaseHelper _dbHelper;

  InterventionNotifier([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper(),
        super(const InterventionState());

  /// Shows the velocity spike banner when rapid scrolling is flagged.
  void triggerVelocityWarning(double velocity) {
    state = state.copyWith(
      isVelocityWarningVisible: true,
      currentVelocity: velocity,
    );
  }

  /// Hides the velocity warning banner.
  void dismissVelocityWarning() {
    state = state.copyWith(isVelocityWarningVisible: false);
  }

  /// Records completed intervention into SQLite intervention_events table.
  Future<void> recordInterventionEvent({
    required String interventionType,
    required String platform,
    required String triggerReason,
    bool completed = true,
    String? selectedAction,
    int dwellTimeMs = 5000,
  }) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(SqliteSchema.tableInterventionEvents, {
        'intervention_type': interventionType,
        'triggered_at': DateTime.now().millisecondsSinceEpoch,
        'platform': platform,
        'trigger_reason': triggerReason,
        'completed': completed ? 1 : 0,
        'selected_action': selectedAction,
        'dwell_time_ms': dwellTimeMs,
      });

      state = state.copyWith(
        completedInterventionsCount: state.completedInterventionsCount + 1,
        isVelocityWarningVisible: false,
      );
    } catch (_) {}
  }
}

/// Provider for interventions.
final interventionProvider =
    StateNotifierProvider<InterventionNotifier, InterventionState>((ref) {
  return InterventionNotifier();
});
