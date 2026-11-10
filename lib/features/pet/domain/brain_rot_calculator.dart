import 'package:brainrot_tracker_pro/features/pet/domain/brain_rot_stage.dart';

/// Immutable state of the rotting brain pet.
class BrainRotPetState {
  final int stageIndex;
  final String stageLabel;
  final String spritePath;
  final double rotPercentage; // 0.0 to 100.0%
  final int petHealth; // 100 - rot (0 to 100)
  final bool isSlimy;
  final bool isSmoking;
  final int? swipesUntilNextStage;
  final int recoveryBonusPoints;

  const BrainRotPetState({
    required this.stageIndex,
    required this.stageLabel,
    required this.spritePath,
    required this.rotPercentage,
    required this.petHealth,
    required this.isSlimy,
    required this.isSmoking,
    this.swipesUntilNextStage,
    this.recoveryBonusPoints = 0,
  });

  BrainRotStage get stage => BrainRotStage.fromIndex(stageIndex);
}

/// Pure math calculator for 7-stage rotting brain progression and recovery bonuses.
class BrainRotCalculator {
  BrainRotCalculator._();

  static const List<int> thresholds = [0, 10, 25, 50, 100, 175, 250];

  static const List<String> labels = [
    'Fresh',
    'Bruised',
    'Foggy',
    'Fried',
    'Mushy',
    'Rotting',
    'Brain rot',
  ];

  /// Computes the active stage index (0 to 6) based on effective swipe count.
  static int calculateStage(int swipeCount) {
    for (int i = thresholds.length - 1; i >= 0; i--) {
      if (swipeCount >= thresholds[i]) return i;
    }
    return 0;
  }

  /// Calculates rot percentage (0.0 to 100.0%), clamped between 0 and 100.
  /// 250 swipes represents 100% brain rot.
  static double calculateRotPercentage(int swipeCount, {int recoveryBonus = 0}) {
    final raw = (swipeCount / 250.0) * 100.0;
    return (raw - recoveryBonus).clamp(0.0, 100.0);
  }

  /// Generates the complete pet state with effective swipe count offset by recovery bonuses.
  static BrainRotPetState computePetState(int swipeCount, {int recoveryBonus = 0}) {
    final effectiveCount = (swipeCount - (recoveryBonus * 2.5)).toInt().clamp(0, 1000);
    final stage = calculateStage(effectiveCount);
    final rotPct = calculateRotPercentage(swipeCount, recoveryBonus: recoveryBonus);

    int? untilNext;
    if (stage < thresholds.length - 1) {
      untilNext = thresholds[stage + 1] - effectiveCount;
    }

    return BrainRotPetState(
      stageIndex: stage,
      stageLabel: labels[stage],
      spritePath: 'assets/images/brain_stage_$stage.png',
      rotPercentage: rotPct,
      petHealth: (100.0 - rotPct).round().clamp(0, 100),
      isSlimy: stage >= 4,
      isSmoking: stage >= 5,
      swipesUntilNextStage: untilNext,
      recoveryBonusPoints: recoveryBonus,
    );
  }
}
