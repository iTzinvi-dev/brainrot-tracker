/// Application-wide constants and configuration values.
class AppConstants {
  AppConstants._();

  // Platform Channel Identifiers
  static const String methodChannelName = 'com.brainrot.tracker/channel';
  static const String eventChannelName = 'com.brainrot.tracker/events';

  // Target Social Package Names
  static const String pkgInstagram = 'com.instagram.android';
  static const String pkgYoutube = 'com.google.android.youtube';
  static const String pkgTikTokMusical = 'com.zhiliaoapp.musically';
  static const String pkgTikTokTrill = 'com.ss.android.ugc.trill';

  // Database
  static const String databaseName = 'brainrot_tracker.db';
  static const int databaseVersion = 1;

  // Defaults & Limits
  static const int defaultDailySwipeLimit = 150;
  static const double warningThresholdRatio = 0.8; // 80% = 120 swipes
  static const double velocitySpikeThresholdSpm = 40.0; // swipes per min
  static const int rapidDwellTimeThresholdMs = 1800; // ms
  static const int breatheScreenDurationSeconds = 5;
  static const int defaultBankingDurationMinutes = 15;

  // Operational CPU Modes
  static const String modeBatterySaver = 'BATTERY_SAVER';
  static const String modeBalanced = 'BALANCED';
  static const String modePerformance = 'PERFORMANCE';
}
