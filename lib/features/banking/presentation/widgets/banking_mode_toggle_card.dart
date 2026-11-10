import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brainrot_tracker_pro/core/constants/app_colors.dart';
import 'package:brainrot_tracker_pro/features/banking/presentation/controllers/banking_mode_controller.dart';

/// Interactive card managing Banking & Focus Mode session pausing.
class BankingModeToggleCard extends ConsumerStatefulWidget {
  const BankingModeToggleCard({super.key});

  @override
  ConsumerState<BankingModeToggleCard> createState() => _BankingModeToggleCardState();
}

class _BankingModeToggleCardState extends ConsumerState<BankingModeToggleCard> {
  int _selectedMinutes = 15;

  String _formatRemainingTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bankingState = ref.watch(bankingModeProvider);
    final isActive = bankingState.isBankingActive;

    return Card(
      color: isActive ? AppColors.surfaceElevated : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive ? AppColors.healthWarning : AppColors.border,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.healthWarning.withOpacity(0.2)
                        : AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isActive ? Icons.lock_clock : Icons.shield_outlined,
                    color: isActive ? AppColors.healthWarning : AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActive ? 'BANKING MODE ACTIVE' : 'BANKING & FOCUS MODE',
                        style: TextStyle(
                          color: isActive ? AppColors.healthWarning : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        isActive
                            ? 'Tracking & rotting brain overlay paused'
                            : 'Pause tracking for 2FA, finance apps, or study',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.healthWarning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.healthWarning),
                    ),
                    child: Text(
                      _formatRemainingTime(bankingState.remainingSeconds),
                      style: const TextStyle(
                        color: AppColors.healthWarning,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (!isActive) ...[
              // Duration selection chips
              Row(
                children: [5, 15, 30, 60].map((mins) {
                  final isSelected = _selectedMinutes == mins;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: ChoiceChip(
                        label: Text('${mins}m'),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withOpacity(0.25),
                        backgroundColor: AppColors.surfaceLight,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedMinutes = mins);
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.pause_circle_filled, size: 18),
                label: Text('Pause Tracking for ${_selectedMinutes}m'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ref.read(bankingModeProvider.notifier).activateBanking(
                        durationMinutes: _selectedMinutes,
                        reason: 'user_pause',
                      );
                },
              ),
            ] else ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Resume Tracking Now'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: const BorderSide(color: AppColors.healthWarning),
                  foregroundColor: AppColors.healthWarning,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ref.read(bankingModeProvider.notifier).deactivateBanking();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
