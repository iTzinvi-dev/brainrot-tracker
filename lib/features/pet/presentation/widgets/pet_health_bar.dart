import 'package:flutter/material.dart';
import 'package:brainrot_tracker_pro/core/constants/app_colors.dart';
import 'package:brainrot_tracker_pro/features/pet/domain/brain_rot_calculator.dart';

/// Interactive health bar showing brain health and rot progression.
class PetHealthBar extends StatelessWidget {
  final BrainRotPetState petState;

  const PetHealthBar({
    super.key,
    required this.petState,
  });

  Color _getHealthColor(int health) {
    if (health >= 75) return AppColors.healthFresh;
    if (health >= 50) return AppColors.healthWarning;
    if (health >= 25) return AppColors.healthRotting;
    return AppColors.healthDanger;
  }

  @override
  Widget build(BuildContext context) {
    final healthColor = _getHealthColor(petState.petHealth);
    final healthRatio = (petState.petHealth / 100.0).clamp(0.0, 1.0);

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: healthColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: healthColor, width: 1),
                      ),
                      child: Text(
                        'Stage ${petState.stageIndex}: ${petState.stageLabel}',
                        style: TextStyle(
                          color: healthColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (petState.recoveryBonusPoints > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+${petState.recoveryBonusPoints}% Mindful',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${petState.petHealth}% HP',
                  style: TextStyle(
                    color: healthColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: healthRatio,
                minHeight: 10,
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(healthColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${petState.rotPercentage.toStringAsFixed(1)}% Brain Rot',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (petState.swipesUntilNextStage != null)
                  Text(
                    '${petState.swipesUntilNextStage} reels to decay',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  const Text(
                    'MAX ROT REACHED',
                    style: TextStyle(
                      color: AppColors.healthDanger,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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
