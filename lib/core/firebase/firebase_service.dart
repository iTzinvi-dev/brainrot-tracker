import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:brainrot_tracker_pro/core/firebase/mock_firebase_options.dart';

/// Service managing Firebase initialization and offline-first persistence.
class FirebaseService {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static final MockSyncService mockSyncService = MockSyncService();

  /// Convenience alias for offline initialization
  static Future<void> initialize() => initializeOfflineFirebase();

  /// Initializes Firebase with offline persistence and default configuration.
  /// Falls back to MockSyncService gracefully if native Firebase bindings are absent.
  static Future<void> initializeOfflineFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: MockFirebaseOptions.currentPlatform,
        );
      }

      // Enable offline persistence on Cloud Firestore
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Remote Config offline fallback defaults
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setDefaults(const {
        'default_daily_swipe_limit': 150,
        'velocity_spike_threshold_spm': 40.0,
        'breathe_screen_duration_seconds': 5,
        'enable_pet_particles': true,
        'banking_auto_resume_minutes': 15,
      });

      _isInitialized = true;
      debugPrint('[FirebaseService] Initialized with offline persistence enabled.');
    } catch (e) {
      debugPrint('[FirebaseService] Running in local offline MockSync mode: $e');
      _isInitialized = false;
    }
  }
}

/// Fallback offline synchronization service when external Firebase project credentials
/// or cloud connectivity are unavailable.
class MockSyncService {
  final Map<String, dynamic> _localMockCache = {};

  Future<void> syncEvent(String collection, String id, Map<String, dynamic> data) async {
    _localMockCache['$collection/$id'] = {
      ...data,
      '_synced_at': DateTime.now().toIso8601String(),
    };
    debugPrint('[MockSyncService] Cached offline record: $collection/$id');
  }

  Map<String, dynamic>? getCachedEvent(String collection, String id) {
    return _localMockCache['$collection/$id'] as Map<String, dynamic>?;
  }

  int get cachedRecordsCount => _localMockCache.length;

  void clearCache() => _localMockCache.clear();
}
