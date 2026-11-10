import 'package:flutter_test/flutter_test.dart';
import 'package:brainrot_tracker_pro/features/banking/presentation/controllers/banking_mode_controller.dart';

void main() {
  group('Tier 1: Banking Mode Activation & Pause Logic', () {
    test('1. Initial BankingModeState is inactive with zero remaining seconds', () {
      const state = BankingModeState();

      expect(state.isBankingActive, isFalse);
      expect(state.sessionId, isNull);
      expect(state.startedAt, isNull);
      expect(state.autoResumeMinutes, equals(15));
      expect(state.remainingSeconds, equals(0));
    });

    test('2. activateBanking sets active flag and generates unique session ID', () {
      final notifier = BankingModeNotifier();
      notifier.activateBanking(durationMinutes: 20, reason: 'exam_study');

      expect(notifier.state.isBankingActive, isTrue);
      expect(notifier.state.sessionId, isNotNull);
      expect(notifier.state.sessionId!.startsWith('bank_'), isTrue);
      expect(notifier.state.autoResumeMinutes, equals(20));
      expect(notifier.state.remainingSeconds, equals(1200)); // 20 * 60
      expect(notifier.state.startedAt, isNotNull);
    });

    test('3. deactivateBanking resets state to inactive', () {
      final notifier = BankingModeNotifier();
      notifier.activateBanking(durationMinutes: 10);
      expect(notifier.state.isBankingActive, isTrue);

      notifier.deactivateBanking();
      expect(notifier.state.isBankingActive, isFalse);
      expect(notifier.state.remainingSeconds, equals(0));
      expect(notifier.state.sessionId, isNull);
    });

    test('4. tickSeconds decrements remaining time correctly', () {
      final notifier = BankingModeNotifier();
      notifier.activateBanking(durationMinutes: 5); // 300s
      expect(notifier.state.remainingSeconds, equals(300));

      notifier.tickSeconds(60);
      expect(notifier.state.remainingSeconds, equals(240));
      expect(notifier.state.isBankingActive, isTrue);
    });

    test('5. Auto-deactivation when remainingSeconds reaches 0', () {
      final notifier = BankingModeNotifier();
      notifier.activateBanking(durationMinutes: 1); // 60s
      expect(notifier.state.isBankingActive, isTrue);

      notifier.tickSeconds(60);
      expect(notifier.state.remainingSeconds, equals(0));
      expect(notifier.state.isBankingActive, isFalse, reason: 'Must auto-resume when timer elapses');
    });

    test('6. Clamping remainingSeconds prevents negative time', () {
      final notifier = BankingModeNotifier();
      notifier.activateBanking(durationMinutes: 1); // 60s

      notifier.tickSeconds(100); // Exceeds remaining 60s
      expect(notifier.state.remainingSeconds, equals(0));
      expect(notifier.state.isBankingActive, isFalse);
    });
  });
}
