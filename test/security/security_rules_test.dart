import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Security Rules and Hardening Tests', () {
    test('Firestore rules enforce default deny and strict owner matching', () {
      final file = File('firebase/firestore.rules');
      expect(file.existsSync(), isTrue, reason: 'firebase/firestore.rules must exist');

      final content = file.readAsStringSync();

      // Default deny
      expect(content, contains('match /{document=**}'));
      expect(content, contains('allow read, write: if false;'));

      // User collection rules
      expect(content, contains('match /users/{userId}'));
      expect(content, contains('request.auth.uid == userId'));

      // Daily stats rules
      expect(content, contains('match /daily_stats/{statId}'));
      expect(content, contains('request.resource.data.userId == request.auth.uid'));
      expect(content, contains('resource.data.userId == request.auth.uid'));

      // Leaderboard read-only, write denied
      expect(content, contains('match /leaderboards/{boardId}'));
      expect(content, contains('allow read: if request.auth != null;'));
      expect(content, contains('allow write: if false;'));
    });

    test('Storage rules enforce default deny, size limits, and image MIME types', () {
      final file = File('firebase/storage.rules');
      expect(file.existsSync(), isTrue, reason: 'firebase/storage.rules must exist');

      final content = file.readAsStringSync();

      // Default deny
      expect(content, contains('match /{allPaths=**}'));
      expect(content, contains('allow read, write: if false;'));

      // User avatar upload rule
      expect(content, contains('match /users/{userId}/{allPaths=**}'));
      expect(content, contains('request.auth.uid == userId'));
      expect(content, contains('5 * 1024 * 1024'));
      expect(content, contains("contentType.matches('image/.*')"));

      // Verify create, update is split from delete
      expect(content, contains('allow create, update:'));
      expect(content, contains('allow delete:'));
    });

    test('Network Security Config strictly disables cleartext HTTP traffic', () {
      final configFile = File('android/app/src/main/res/xml/network_security_config.xml');
      expect(configFile.existsSync(), isTrue);

      final content = configFile.readAsStringSync();
      expect(content, contains('cleartextTrafficPermitted="false"'));
      expect(content, contains('<certificates src="system"'));
    });

    test('AndroidManifest configures network security and prohibits cleartext', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue);

      final content = manifestFile.readAsStringSync();
      expect(content, contains('android:networkSecurityConfig="@xml/network_security_config"'));
      expect(content, contains('android:usesCleartextTraffic="false"'));
    });

    test('DatabaseHelper uses parameterized arguments for all SQLite operations', () {
      final dbHelperFile = File('lib/core/database/database_helper.dart');
      expect(dbHelperFile.existsSync(), isTrue);

      final content = dbHelperFile.readAsStringSync();

      // Ensure no raw string interpolation in rawQuery / rawUpdate / rawDelete
      expect(content, isNot(matches(RegExp(r'rawQuery\s*\(\s*["\x27][^"\x27]*\$'))));
      expect(content, isNot(matches(RegExp(r'rawUpdate\s*\(\s*["\x27][^"\x27]*\$'))));
      expect(content, isNot(matches(RegExp(r'rawDelete\s*\(\s*["\x27][^"\x27]*\$'))));

      // Check parameterized queries with whereArgs
      expect(content, contains('whereArgs:'));
    });

    test('Repositories and controllers use parameterized arguments for SQLite queries', () {
      final repoFile = File('lib/features/tracking/data/event_sourced_tracking_repository.dart');
      expect(repoFile.existsSync(), isTrue);
      final repoContent = repoFile.readAsStringSync();

      expect(repoContent, isNot(matches(RegExp(r'rawQuery\s*\(\s*["\x27][^"\x27]*\$'))));
      expect(repoContent, contains('whereArgs:'));
      expect(repoContent, contains('WHERE timestamp >= ?'));

      final bankingFile = File('lib/features/banking/presentation/controllers/banking_mode_controller.dart');
      expect(bankingFile.existsSync(), isTrue);
      final bankingContent = bankingFile.readAsStringSync();

      expect(bankingContent, contains('whereArgs:'));
      expect(bankingContent, contains("where: 'session_id = ?'"));
    });

    test('SafeLogger redacts sensitive tokens, passwords, and errors', () {
      final safeLoggerFile = File('lib/core/logging/safe_logger.dart');
      expect(safeLoggerFile.existsSync(), isTrue);

      final content = safeLoggerFile.readAsStringSync();

      // Ensure error redaction in warning and error methods
      expect(content, contains(r'redact(error.toString())'));
      expect(content, contains('!kReleaseMode'));
    });
  });
}
