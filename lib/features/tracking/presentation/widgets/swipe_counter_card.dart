import 'package:flutter/material.dart';
import 'package:brainrot_tracker_pro/core/constants/app_colors.dart';

/// Card displaying the today's cumulative swipe count and real-time scrolling velocity.
class SwipeCounterCard extends StatelessWidget {
  final int totalSwipes;
  final double currentVelocity;
  final int targetLimit;

  const SwipeCounterCard({
    super.key,
    required this.totalSwipes,
    required this.currentVelocity,
    this.targetLimit = 150,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = (totalSwipes / targetLimit).clamp(0.0, 1.0);
    final bool isRapid = currentVelocity > 40.0;

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isRapid ? AppColors.healthDanger : AppColors.border,
          width: isRapid ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TODAY\'S REELS SCROLLED',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isRapid
                        ? AppColors.healthDanger.withOpacity(0.15)
                        : AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isRapid ? AppColors.healthDanger : AppColors.primary,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isRapid ? Icons.speed : Icons.bolt,
                        size: 14,
                        color: isRapid ? AppColors.healthDanger : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${currentVelocity.toStringAsFixed(1)} /min',
                        style: TextStyle(
                          color: isRapid ? AppColors.healthDanger : AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$totalSwipes',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '/ $targetLimit limit',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0
                      ? AppColors.healthDanger
                      : progress >= 0.8
                          ? AppColors.healthWarning
                          : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toInt()}% of daily quota',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                Text(
                  totalSwipes >= targetLimit
                      ? 'Limit reached!'
                      : '${targetLimit - totalSwipes} remaining',
                  style: TextStyle(
                    color: totalSwipes >= targetLimit ? AppColors.healthDanger : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
