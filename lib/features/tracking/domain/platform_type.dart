/// Supported short-form video platforms tracked by Brainrot Tracker Pro.
enum PlatformType {
  instagram(
    displayName: 'Instagram Reels',
    packageName: 'com.instagram.android',
    colorHex: 0xFFE1306C,
  ),
  youtube(
    displayName: 'YouTube Shorts',
    packageName: 'com.google.android.youtube',
    colorHex: 0xFFFF0000,
  ),
  tiktok(
    displayName: 'TikTok',
    packageName: 'com.zhiliaoapp.musically',
    colorHex: 0xFF00F2FE,
  );

  final String displayName;
  final String packageName;
  final int colorHex;

  const PlatformType({
    required this.displayName,
    required this.packageName,
    required this.colorHex,
  });

  /// Factory method to map Android package names to supported PlatformType.
  /// Handles case variations and substring matching, defaulting to tiktok.
  static PlatformType fromPackageName(String packageName) {
    final lower = packageName.toLowerCase();
    if (lower.contains('instagram')) {
      return PlatformType.instagram;
    } else if (lower.contains('youtube')) {
      return PlatformType.youtube;
    } else if (lower.contains('musically') ||
        lower.contains('trill') ||
        lower.contains('tiktok')) {
      return PlatformType.tiktok;
    }
    // Fallback defaults to tiktok feed format
    return PlatformType.tiktok;
  }
}
