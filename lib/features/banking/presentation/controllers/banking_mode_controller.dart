import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brainrot_tracker_pro/core/database/database_helper.dart';
import 'package:brainrot_tracker_pro/core/database/sqlite_schema.dart';
import 'package:brainrot_tracker_pro/features/tracking/presentation/controllers/tracking_controller.dart';

/// State of banking / focus mode tracking pause.
class BankingModeState {
  final bool isBankingActive;
  final String? sessionId;
  final DateTime? startedAt;
  final int autoResumeMinutes;
  final int remainingSeconds;

  const BankingModeState({
    this.isBankingActive = false,
    this.sessionId,
    this.startedAt,
    this.autoResumeMinutes = 15,
    this.remainingSeconds = 0,
  });

  BankingModeState copyWith({
    bool? isBankingActive,
    String? sessionId,
    DateTime? startedAt,
    int? autoResumeMinutes,
    int? remainingSeconds,
  }) {
    return BankingModeState(
      isBankingActive: isBankingActive ?? this.isBankingActive,
      sessionId: sessionId ?? this.sessionId,
      startedAt: startedAt ?? this.startedAt,
      autoResumeMinutes: autoResumeMinutes ?? this.autoResumeMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }
}

/// Notifier governing banking mode session lifecycle and SQLite persistence.
class BankingModeNotifier extends StateNotifier<BankingModeState> {
  final Ref? _ref;
  final DatabaseHelper _dbHelper;
  Timer? _countdownTimer;

  BankingModeNotifier([Ref? ref, DatabaseHelper? dbHelper])
      : _ref = ref,
        _dbHelper = dbHelper ?? DatabaseHelper(),
        super(const BankingModeState());

  /// Activates banking mode, pausing reel tracking and overlay rendering.
  Future<void> activateBanking({int durationMinutes = 15, String reason = 'banking'}) async {
    final session = 'bank_${DateTime.now().millisecondsSinceEpoch}';
    final totalSeconds = durationMinutes * 60;

    state = BankingModeState(
      isBankingActive: true,
      sessionId: session,
      startedAt: DateTime.now(),
      autoResumeMinutes: durationMinutes,
      remainingSeconds: totalSeconds,
    );

    // Pause tracking controller
    _ref?.read(trackingProvider.notifier).setBankingState(true);

    // Record session to SQLite
    try {
      final db = await _dbHelper.database;
      await db.insert(SqliteSchema.tableBankingSessions, {
        'session_id': session,
        'start_timestamp': DateTime.now().millisecondsSinceEpoch,
        'reason': reason,
        'auto_resume_minutes': durationMinutes,
        'status': 'active',
      });
    } catch (_) {}

    // Start auto-resume countdown
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      tickSeconds(1);
    });
  }

  /// Manually deactivates banking mode and resumes normal tracking.
  Future<void> deactivateBanking() async {
    _countdownTimer?.cancel();
    _countdownTimer = null;

    final sessionId = state.sessionId;
    state = const BankingModeState(isBankingActive: false);

    // Resume tracking controller
    _ref?.read(trackingProvider.notifier).setBankingState(false);

    // Update SQLite session status
    if (sessionId != null) {
      try {
        final db = await _dbHelper.database;
        await db.update(
          SqliteSchema.tableBankingSessions,
          {
            'end_timestamp': DateTime.now().millisecondsSinceEpoch,
            'status': 'completed',
          },
          where: 'session_id = ?',
          whereArgs: [sessionId],
        );
      } catch (_) {}
    }
  }

  /// Manually advances the countdown timer by [seconds] (clamped to 0).
  /// Automatically deactivates banking mode when remaining time reaches 0.
  void tickSeconds(int seconds) {
    if (!state.isBankingActive) return;
    final newRemaining = (state.remainingSeconds - seconds).clamp(0, 86400);
    if (newRemaining <= 0) {
      deactivateBanking();
    } else {
      state = state.copyWith(remainingSeconds: newRemaining);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}

/// Provider for banking mode.
final bankingModeProvider =
    StateNotifierProvider<BankingModeNotifier, BankingModeState>((ref) {
  return BankingModeNotifier(ref);
});
