import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brainrot_tracker_pro/features/pet/domain/brain_rot_calculator.dart';
import 'package:brainrot_tracker_pro/features/tracking/presentation/controllers/tracking_controller.dart';

/// Notifier driving the 7-stage rotting brain pet gamification.
class PetNotifier extends StateNotifier<BrainRotPetState> {
  int _lastRawSwipes = 0;

  PetNotifier() : super(BrainRotCalculator.computePetState(0));

  /// Updates pet progression when new doomscroll swipes are logged.
  void updateWithSwipeCount(int totalSwipes) {
    _lastRawSwipes = totalSwipes;
    state = BrainRotCalculator.computePetState(
      totalSwipes,
      recoveryBonus: state.recoveryBonusPoints,
    );
  }

  /// Heals brain rot via mindful actions (Breathe screen, dopamine micro-rewards).
  void applyMindfulRecovery(int bonusPercentage) {
    final updatedBonus = (state.recoveryBonusPoints + bonusPercentage).clamp(0, 80);
    state = BrainRotCalculator.computePetState(
      _lastRawSwipes,
      recoveryBonus: updatedBonus,
    );
  }

  /// Resets recovery bonuses (e.g. at start of day).
  void resetBonus() {
    state = BrainRotCalculator.computePetState(
      _lastRawSwipes,
      recoveryBonus: 0,
    );
  }
}

/// Pet state provider synchronized with tracking events.
final petProvider = StateNotifierProvider<PetNotifier, BrainRotPetState>((ref) {
  final notifier = PetNotifier();
  ref.listen<TrackingState>(trackingProvider, (prev, next) {
    if (prev?.totalToday != next.totalToday) {
      notifier.updateWithSwipeCount(next.totalToday);
    }
  });
  return notifier;
});
