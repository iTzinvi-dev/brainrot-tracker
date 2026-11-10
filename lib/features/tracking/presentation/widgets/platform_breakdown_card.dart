import 'package:flutter/material.dart';
import 'package:brainrot_tracker_pro/core/constants/app_colors.dart';
import 'package:brainrot_tracker_pro/features/tracking/domain/platform_type.dart';

/// Card presenting usage distribution across Instagram Reels, YouTube Shorts, and TikTok.
class PlatformBreakdownCard extends StatelessWidget {
  final Map<PlatformType, int> platformCounts;

  const PlatformBreakdownCard({
    super.key,
    required this.platformCounts,
  });

  @override
  Widget build(BuildContext context) {
    final int total = platformCounts.values.fold(0, (sum, c) => sum + c);

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PLATFORM BREAKDOWN',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            // Multi-segment progress bar
            if (total > 0)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: PlatformType.values.map((platform) {
                      final count = platformCounts[platform] ?? 0;
                      final flex = (count * 1000 ~/ total);
                      if (flex <= 0) return const SizedBox.shrink();
                      return Expanded(
                        flex: flex,
                        child: Container(color: Color(platform.colorHex)),
                      );
                    }).toList(),
                  ),
                ),
              )
            else
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            const SizedBox(height: 16),
            // Platform rows
            ...PlatformType.values.map((platform) {
              final count = platformCounts[platform] ?? 0;
              final double percentage = total > 0 ? (count / total) * 100 : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Color(platform.colorHex),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        platform.displayName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '$count',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '${percentage.toStringAsFixed(0)}%',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
