import 'package:flutter_test/flutter_test.dart';
import 'package:brainrot_tracker_pro/features/pet/domain/brain_rot_calculator.dart';
import 'package:brainrot_tracker_pro/features/pet/presentation/controllers/pet_controller.dart';

void main() {
  group('Tier 1: BrainRotCalculator & Stage Transitions', () {
    test('1. Stage 0 (Fresh): 0 to 9 swipes maintains healthy state', () {
      for (int swipes = 0; swipes < 10; swipes++) {
        final stage = BrainRotCalculator.calculateStage(swipes);
        expect(stage, equals(0), reason: 'Swipe count $swipes must be Stage 0');

        final petState = BrainRotCalculator.computePetState(swipes);
        expect(petState.stageIndex, equals(0));
        expect(petState.stageLabel, equals('Fresh'));
        expect(petState.spritePath, equals('assets/images/brain_stage_0.png'));
        expect(petState.isSlimy, isFalse);
        expect(petState.isSmoking, isFalse);
        expect(petState.petHealth, greaterThanOrEqualTo(96));
        expect(petState.rotPercentage, lessThanOrEqualTo(4.0));
      }
    });

    test('2. Stage 1 (Bruised): 10 to 24 swipes', () {
      final state10 = BrainRotCalculator.computePetState(10);
      expect(state10.stageIndex, equals(1));
      expect(state10.stageLabel, equals('Bruised'));
      expect(state10.spritePath, equals('assets/images/brain_stage_1.png'));
      expect(state10.isSlimy, isFalse);
      expect(state10.isSmoking, isFalse);
      expect(state10.rotPercentage, closeTo(4.0, 0.1)); // 10/250 = 4%

      final state24 = BrainRotCalculator.computePetState(24);
      expect(state24.stageIndex, equals(1));
      expect(state24.swipesUntilNextStage, equals(1)); // 25 - 24 = 1
    });

    test('3. Stage 2 (Foggy) and Stage 3 (Fried) boundary checks', () {
      final state25 = BrainRotCalculator.computePetState(25);
      expect(state25.stageIndex, equals(2));
      expect(state25.stageLabel, equals('Foggy'));
      expect(state25.spritePath, equals('assets/images/brain_stage_2.png'));

      final state49 = BrainRotCalculator.computePetState(49);
      expect(state49.stageIndex, equals(2));
      expect(state49.swipesUntilNextStage, equals(1));

      final state50 = BrainRotCalculator.computePetState(50);
      expect(state50.stageIndex, equals(3));
      expect(state50.stageLabel, equals('Fried'));
      expect(state50.spritePath, equals('assets/images/brain_stage_3.png'));
      expect(state50.rotPercentage, closeTo(20.0, 0.1)); // 50/250 = 20%
    });

    test('4. Stage 4 (Mushy): Slime activation at 100 swipes', () {
      final state99 = BrainRotCalculator.computePetState(99);
      expect(state99.stageIndex, equals(3));
      expect(state99.isSlimy, isFalse);

      final state100 = BrainRotCalculator.computePetState(100);
      expect(state100.stageIndex, equals(4));
      expect(state100.stageLabel, equals('Mushy'));
      expect(state100.spritePath, equals('assets/images/brain_stage_4.png'));
      expect(state100.isSlimy, isTrue, reason: 'Stage >= 4 must activate green slime');
      expect(state100.isSmoking, isFalse);
      expect(state100.rotPercentage, closeTo(40.0, 0.1)); // 100/250 = 40%
    });

    test('5. Stage 5 (Rotting): Smoke activation at 175 swipes', () {
      final state174 = BrainRotCalculator.computePetState(174);
      expect(state174.stageIndex, equals(4));
      expect(state174.isSmoking, isFalse);

      final state175 = BrainRotCalculator.computePetState(175);
      expect(state175.stageIndex, equals(5));
      expect(state175.stageLabel, equals('Rotting'));
      expect(state175.spritePath, equals('assets/images/brain_stage_5.png'));
      expect(state175.isSlimy, isTrue);
      expect(state175.isSmoking, isTrue, reason: 'Stage >= 5 must activate smoke plume');
      expect(state175.rotPercentage, closeTo(70.0, 0.1)); // 175/250 = 70%
    });

    test('6. Stage 6 (Brain rot): Max stage reached at 250+ swipes', () {
      final state250 = BrainRotCalculator.computePetState(250);
      expect(state250.stageIndex, equals(6));
      expect(state250.stageLabel, equals('Brain rot'));
      expect(state250.spritePath, equals('assets/images/brain_stage_6.png'));
      expect(state250.rotPercentage, closeTo(100.0, 0.1));
      expect(state250.petHealth, equals(0));
      expect(state250.isSlimy, isTrue);
      expect(state250.isSmoking, isTrue);
      expect(state250.swipesUntilNextStage, isNull, reason: 'Terminal stage has no next threshold');

      // Clamping check for swipes > 250
      final state500 = BrainRotCalculator.computePetState(500);
      expect(state500.stageIndex, equals(6));
      expect(state500.rotPercentage, equals(100.0));
      expect(state500.petHealth, equals(0));
    });

    test('7. Recovery bonus mechanics: reduces rot percentage and improves health', () {
      // 100 swipes gives 40% rot without bonus
      final stateNoBonus = BrainRotCalculator.computePetState(100, recoveryBonus: 0);
      expect(stateNoBonus.rotPercentage, closeTo(40.0, 0.1));
      expect(stateNoBonus.petHealth, equals(60));

      // 100 swipes with 15% recovery bonus gives 25% rot
      final stateWithBonus = BrainRotCalculator.computePetState(100, recoveryBonus: 15);
      expect(stateWithBonus.rotPercentage, closeTo(25.0, 0.1));
      expect(stateWithBonus.petHealth, equals(75));
      expect(stateWithBonus.recoveryBonusPoints, equals(15));
    });
  });
}
