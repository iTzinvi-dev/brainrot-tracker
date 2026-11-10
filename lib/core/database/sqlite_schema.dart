/// SQLite Schema definitions and table creation queries for Brainrot Tracker Pro.
/// Event-sourced architecture: discrete events are appended and aggregated on-demand.
class SqliteSchema {
  SqliteSchema._();

  /// 1. Scroll Events Table
  /// Logs discrete video view settle events with epoch ms timestamps.
  static const String tableScrollEvents = 'scroll_events';
  static const String createTableScrollEvents = '''
    CREATE TABLE IF NOT EXISTS $tableScrollEvents (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id TEXT NOT NULL,
      platform TEXT NOT NULL,
      timestamp INTEGER NOT NULL,
      page_index INTEGER NOT NULL,
      duration_ms INTEGER NOT NULL DEFAULT 0,
      is_rapid_scroll INTEGER NOT NULL DEFAULT 0,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(session_id, platform, page_index, timestamp)
    );
  ''';

  static const String createIndexScrollEventsTs = '''
    CREATE INDEX IF NOT EXISTS idx_scroll_events_ts ON $tableScrollEvents(timestamp);
  ''';

  static const String createIndexScrollEventsPlatformTs = '''
    CREATE INDEX IF NOT EXISTS idx_scroll_events_platform_ts ON $tableScrollEvents(platform, timestamp);
  ''';

  static const String createIndexScrollEventsSession = '''
    CREATE INDEX IF NOT EXISTS idx_scroll_events_session ON $tableScrollEvents(session_id);
  ''';

  /// 2. Daily Limits Table
  /// Tracks daily usage limit targets, warning thresholds, and lock states per date.
  static const String tableDailyLimits = 'daily_limits';
  static const String createTableDailyLimits = '''
    CREATE TABLE IF NOT EXISTS $tableDailyLimits (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date_str TEXT UNIQUE NOT NULL,
      target_limit INTEGER NOT NULL,
      warning_threshold INTEGER NOT NULL,
      exceeded_at INTEGER,
      is_locked INTEGER NOT NULL DEFAULT 0,
      updated_at INTEGER NOT NULL
    );
  ''';

  /// 3. Banking Sessions Table
  /// Records productivity/banking mode pause intervals.
  static const String tableBankingSessions = 'banking_sessions';
  static const String createTableBankingSessions = '''
    CREATE TABLE IF NOT EXISTS $tableBankingSessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id TEXT UNIQUE NOT NULL,
      start_timestamp INTEGER NOT NULL,
      end_timestamp INTEGER,
      reason TEXT NOT NULL DEFAULT 'banking',
      auto_resume_minutes INTEGER NOT NULL DEFAULT 15,
      status TEXT NOT NULL DEFAULT 'active'
    );
  ''';

  /// 4. Intervention Events Table
  /// Audit trail of anti-doomscroll interventions (breathe screen, dopamine menu, velocity limiter).
  static const String tableInterventionEvents = 'intervention_events';
  static const String createTableInterventionEvents = '''
    CREATE TABLE IF NOT EXISTS $tableInterventionEvents (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      intervention_type TEXT NOT NULL,
      triggered_at INTEGER NOT NULL,
      platform TEXT NOT NULL,
      trigger_reason TEXT NOT NULL,
      completed INTEGER NOT NULL DEFAULT 0,
      selected_action TEXT,
      dwell_time_ms INTEGER NOT NULL DEFAULT 0
    );
  ''';

  /// All creation queries executed on database initialization.
  static const List<String> allCreateStatements = [
    createTableScrollEvents,
    createIndexScrollEventsTs,
    createIndexScrollEventsPlatformTs,
    createIndexScrollEventsSession,
    createTableDailyLimits,
    createTableBankingSessions,
    createTableInterventionEvents,
  ];
}
