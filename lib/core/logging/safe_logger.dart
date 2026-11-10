import 'package:flutter/foundation.dart';

/// Secure logging utility for Brainrot Tracker Pro.
/// Suppresses debug logs in release mode and redacts sensitive credentials/tokens.
class SafeLogger {
  final String tag;

  const SafeLogger([this.tag = 'BrainrotTracker']);

  static final RegExp _passwordRegex = RegExp(
    r'(password["\s:=]+)(["\']?)([^"\'\s,;&]+)\2',
    caseSensitive: false,
  );

  static final RegExp _tokenRegex = RegExp(
    r'((?:bearer|token|secret|apiKey|idToken|refreshToken)["\s:=]+)(["\']?)([^"\'\s,;&]+)\2',
    caseSensitive: false,
  );

  /// Redacts sensitive keys and values from log messages.
  static String redact(String message) {
    var sanitized = message.replaceAllMapped(_passwordRegex, (match) {
      return '${match.group(1)}[REDACTED]';
    });
    sanitized = sanitized.replaceAllMapped(_tokenRegex, (match) {
      return '${match.group(1)}[REDACTED]';
    });
    return sanitized;
  }

  void debug(String message) {
    if (!kReleaseMode) {
      debugPrint('[$tag][DEBUG] ${redact(message)}');
    }
  }

  void info(String message) {
    if (!kReleaseMode) {
      debugPrint('[$tag][INFO] ${redact(message)}');
    }
  }

  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[$tag][WARN] ${redact(message)}');
    if (error != null) {
      debugPrint('[$tag][WARN ERROR] ${redact(error.toString())}');
    }
    if (stackTrace != null && !kReleaseMode) {
      debugPrint('[$tag][WARN STACK] $stackTrace');
    }
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[$tag][ERROR] ${redact(message)}');
    if (error != null) {
      debugPrint('[$tag][ERROR DETAILS] ${redact(error.toString())}');
    }
    if (stackTrace != null && !kReleaseMode) {
      debugPrint('[$tag][ERROR STACK] $stackTrace');
    }
  }
}
