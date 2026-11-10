import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brainrot_tracker_pro/features/auth/data/mock_auth_repository.dart';
import 'package:brainrot_tracker_pro/features/auth/presentation/controllers/auth_controller.dart';
import 'package:brainrot_tracker_pro/features/auth/presentation/controllers/auth_state.dart';
import 'package:brainrot_tracker_pro/features/auth/presentation/controllers/rate_limiter_notifier.dart';

void main() {
  group('AuthController Riverpod State Tests', () {
    late ProviderContainer container;
    late MockAuthRepository mockRepo;

    setUp(() {
      mockRepo = MockAuthRepository(seedDevAccount: true);
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      mockRepo.dispose();
    });

    test('initial state is unauthenticated when no user is signed in', () {
      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.user, isNull);
      expect(state.isLoading, false);
    });

    test('signInWithEmail transitions to authenticated on valid credentials', () async {
      final controller = container.read(authControllerProvider.notifier);

      await controller.signInWithEmail('dev@brainrot.app', 'Password123!');

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user?.email, 'dev@brainrot.app');
      expect(state.errorMessage, isNull);
    });

    test('signInWithEmail increments rate limiter failure count on error', () async {
      final controller = container.read(authControllerProvider.notifier);

      await controller.signInWithEmail('dev@brainrot.app', 'WrongPass!');

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, isNotNull);

      final rateLimiterState = container.read(rateLimiterProvider);
      expect(rateLimiterState.failedAttempts, 1);
      expect(rateLimiterState.isLocked, false);
    });

    test('5 consecutive failed sign-in attempts locks out the user and intercepts attempts', () async {
      final controller = container.read(authControllerProvider.notifier);

      for (int i = 0; i < 5; i++) {
        await controller.signInWithEmail('dev@brainrot.app', 'WrongPass!');
      }

      final rateLimiterState = container.read(rateLimiterProvider);
      expect(rateLimiterState.failedAttempts, 5);
      expect(rateLimiterState.isLocked, true);
      expect(rateLimiterState.remainingSeconds, greaterThan(0));

      // 6th attempt should be intercepted by rate limiter
      await controller.signInWithEmail('dev@brainrot.app', 'Password123!');
      final stateAfter = container.read(authControllerProvider);
      expect(stateAfter.status, AuthStatus.error);
      expect(stateAfter.errorMessage, contains('Locked out'));
    });

    test('successful sign-in resets rate limiter', () async {
      final controller = container.read(authControllerProvider.notifier);

      // 2 failed attempts
      await controller.signInWithEmail('dev@brainrot.app', 'Wrong1!');
      await controller.signInWithEmail('dev@brainrot.app', 'Wrong2!');
      expect(container.read(rateLimiterProvider).failedAttempts, 2);

      // Now successful sign-in
      await controller.signInWithEmail('dev@brainrot.app', 'Password123!');

      expect(container.read(rateLimiterProvider).failedAttempts, 0);
      expect(container.read(rateLimiterProvider).isLocked, false);
    });

    test('signOut transitions state back to unauthenticated', () async {
      final controller = container.read(authControllerProvider.notifier);
      await controller.signInWithEmail('dev@brainrot.app', 'Password123!');
      expect(container.read(authControllerProvider).status, AuthStatus.authenticated);

      await controller.signOut();
      expect(container.read(authControllerProvider).status, AuthStatus.unauthenticated);
      expect(container.read(authControllerProvider).user, isNull);
    });
  });
}
