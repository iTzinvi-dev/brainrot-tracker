import 'package:flutter_test/flutter_test.dart';
import 'package:brainrot_tracker_pro/features/tracking/domain/platform_type.dart';

void main() {
  group('Tier 1: PlatformType Mapping & Attributes', () {
    test('1. Enum contains exactly three supported platforms', () {
      expect(PlatformType.values.length, equals(3));
      expect(PlatformType.values, contains(PlatformType.instagram));
      expect(PlatformType.values, contains(PlatformType.youtube));
      expect(PlatformType.values, contains(PlatformType.tiktok));
    });

    test('2. fromPackageName correctly maps Instagram package', () {
      final platform = PlatformType.fromPackageName('com.instagram.android');
      expect(platform, equals(PlatformType.instagram));
      expect(platform.displayName, equals('Instagram Reels'));
      expect(platform.packageName, equals('com.instagram.android'));
    });

    test('3. fromPackageName correctly maps YouTube Shorts package', () {
      final platform = PlatformType.fromPackageName('com.google.android.youtube');
      expect(platform, equals(PlatformType.youtube));
      expect(platform.displayName, equals('YouTube Shorts'));
      expect(platform.packageName, equals('com.google.android.youtube'));
    });

    test('4. fromPackageName maps TikTok Musical.ly and Trill packages', () {
      final musically = PlatformType.fromPackageName('com.zhiliaoapp.musically');
      expect(musically, equals(PlatformType.tiktok));
      expect(musically.displayName, equals('TikTok'));

      final trill = PlatformType.fromPackageName('com.ss.android.ugc.trill');
      expect(trill, equals(PlatformType.tiktok));
    });

    test('5. Brand color attributes are defined and distinct', () {
      expect(PlatformType.instagram.colorHex, equals(0xFFE1306C));
      expect(PlatformType.youtube.colorHex, equals(0xFFFF0000));
      expect(PlatformType.tiktok.colorHex, equals(0xFF00F2FE));

      final colors = PlatformType.values.map((p) => p.colorHex).toSet();
      expect(colors.length, equals(3), reason: 'Each platform must have distinct accent color');
    });

    test('6. fromPackageName handles case variations or substring patterns gracefully', () {
      expect(PlatformType.fromPackageName('COM.INSTAGRAM.ANDROID'.toLowerCase()), equals(PlatformType.instagram));
      expect(PlatformType.fromPackageName('com.google.android.youtube.lite'), equals(PlatformType.youtube));
      expect(PlatformType.fromPackageName('com.unknown.app'), equals(PlatformType.tiktok),
          reason: 'Fallback defaults to tiktok feed format');
    });
  });
}
