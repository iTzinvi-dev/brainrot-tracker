import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

/// Firebase Options supporting both `.env` / `--dart-define-from-file` environment
/// variables and local offline development defaults.
class MockFirebaseOptions {
  MockFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_API_KEY_ANDROID',
      defaultValue: 'AIzaSyMockKeyPlaceholderForOfflineDev12345',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_APP_ID_ANDROID',
      defaultValue: '1:123456789012:android:abcdef0123456789abcdef',
    ),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: '123456789012',
    ),
    projectId: String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: 'brainrot-tracker-pro-dev',
    ),
    storageBucket: String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: 'brainrot-tracker-pro-dev.appspot.com',
    ),
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_API_KEY_IOS',
      defaultValue: 'AIzaSyMockKeyPlaceholderForOfflineDev12345',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_APP_ID_IOS',
      defaultValue: '1:123456789012:ios:abcdef0123456789abcdef',
    ),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: '123456789012',
    ),
    projectId: String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: 'brainrot-tracker-pro-dev',
    ),
    storageBucket: String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: 'brainrot-tracker-pro-dev.appspot.com',
    ),
    iosBundleId: 'com.brainrot.tracker',
  );
}
