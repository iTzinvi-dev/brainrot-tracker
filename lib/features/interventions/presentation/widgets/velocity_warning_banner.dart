import 'package:flutter/material.dart';
import 'package:brainrot_tracker_pro/core/constants/app_colors.dart';

/// Warning banner displayed when high velocity doomscrolling or rapid skimming is detected.
class VelocityWarningBanner extends StatelessWidget {
  final double currentVelocity;
  final VoidCallback onBreathePressed;
  final VoidCallback? onDismiss;

  const VelocityWarningBanner({
    super.key,
    required this.currentVelocity,
    required this.onBreathePressed,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.healthDanger, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.healthDanger.withOpacity(0.2),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.healthDanger.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.speed,
              color: AppColors.healthDanger,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'RAPID SWIPING DETECTED',
                  style: TextStyle(
                    color: AppColors.healthDanger,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pacing: ${currentVelocity.toStringAsFixed(1)} swipes/min. Dopamine reflex engaged.',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(60, 36),
            ),
            onPressed: onBreathePressed,
            child: const Text('Breathe'),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
