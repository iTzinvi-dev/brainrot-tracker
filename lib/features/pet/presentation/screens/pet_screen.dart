import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brainrot_tracker_pro/core/constants/app_colors.dart';
import 'package:brainrot_tracker_pro/features/interventions/presentation/screens/breathe_screen.dart';
import 'package:brainrot_tracker_pro/features/interventions/presentation/screens/dopamine_menu_screen.dart';
import 'package:brainrot_tracker_pro/features/pet/domain/brain_rot_stage.dart';
import 'package:brainrot_tracker_pro/features/pet/presentation/controllers/pet_controller.dart';
import 'package:brainrot_tracker_pro/features/pet/presentation/widgets/pet_avatar_widget.dart';
import 'package:brainrot_tracker_pro/features/pet/presentation/widgets/pet_health_bar.dart';

/// Screen showcasing the 7-stage rotting brain pet, health stats, and recovery actions.
class PetScreen extends ConsumerWidget {
  const PetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petState = ref.watch(petProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Neural Pet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            tooltip: 'Reset Recovery Bonus',
            onPressed: () {
              ref.read(petProvider.notifier).resetBonus();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recovery bonuses reset for today.')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Rotting Brain Avatar
            PetAvatarWidget(
              petState: petState,
              size: 220,
            ),
            const SizedBox(height: 16),

            // Stage Title & Subtitle
            Text(
              petState.stageLabel.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              petState.stage.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Health Bar Card
            PetHealthBar(petState: petState),
            const SizedBox(height: 24),

            // Mindful Healing Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.air, size: 20),
                    label: const Text('Breathe (+10%)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textInverse,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BreatheScreen(
                            onResume: () {
                              ref.read(petProvider.notifier).applyMindfulRecovery(10);
                              Navigator.of(context).pop();
                            },
                            onExitToMenu: () {
                              ref.read(petProvider.notifier).applyMindfulRecovery(10);
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const DopamineMenuScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.restaurant_menu, size: 20),
                    label: const Text('Dopamine Menu'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DopamineMenuScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 7 Stages Roadmap
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ROT STAGES ROADMAP',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...BrainRotStage.values.map((stage) {
              final isCurrent = stage.stageIndex == petState.stageIndex;
              final isPassed = stage.stageIndex < petState.stageIndex;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.surfaceLight
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrent
                        ? Color(stage.colorHex)
                        : isPassed
                            ? AppColors.border
                            : AppColors.surfaceLight,
                    width: isCurrent ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Color(stage.colorHex).withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Color(stage.colorHex), width: 1),
                      ),
                      child: Center(
                        child: Text(
                          '${stage.stageIndex}',
                          style: TextStyle(
                            color: Color(stage.colorHex),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage.label,
                            style: TextStyle(
                              color: isCurrent ? AppColors.textPrimary : AppColors.textSecondary,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${stage.thresholdSwipes}+ reels threshold',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(stage.colorHex).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Color(stage.colorHex),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
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
