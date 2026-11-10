import 'package:flutter_test/flutter_test.dart';
import 'package:brainrot_tracker_pro/features/auth/domain/rate_limiter.dart';

void main() {
  group('RateLimiter Domain Tests', () {
    late DateTime currentTime;
    late RateLimiter rateLimiter;

    setUp(() {
      currentTime = DateTime(2026, 11, 10, 10, 0, 0);
      rateLimiter = RateLimiter(
        maxAttempts: 5,
        lockoutDuration: const Duration(seconds: 30),
        clock: () => currentTime,
      );
    });

    test('initial state has 0 failed attempts and is not locked', () {
      expect(rateLimiter.failedAttempts, 0);
      expect(rateLimiter.isLocked, false);
      expect(rateLimiter.remainingSeconds, 0);
    });

    test('attempts 1 to 4 record failure without triggering lockout', () {
      for (int i = 1; i <= 4; i++) {
        rateLimiter.recordFailedAttempt();
        expect(rateLimiter.failedAttempts, i);
        expect(rateLimiter.isLocked, false);
        expect(rateLimiter.remainingSeconds, 0);
      }
    });

    test('5th consecutive failed attempt triggers 30-second lockout', () {
      for (int i = 0; i < 5; i++) {
        rateLimiter.recordFailedAttempt();
      }

      expect(rateLimiter.failedAttempts, 5);
      expect(rateLimiter.isLocked, true);
      expect(rateLimiter.remainingSeconds, 30);
    });

    test('lockout counts down as time progresses and expires after 30 seconds', () {
      for (int i = 0; i < 5; i++) {
        rateLimiter.recordFailedAttempt();
      }
      expect(rateLimiter.isLocked, true);

      // Advance 10 seconds
      currentTime = currentTime.add(const Duration(seconds: 10));
      expect(rateLimiter.isLocked, true);
      expect(rateLimiter.remainingSeconds, 20);

      // Advance another 19 seconds (total 29s elapsed)
      currentTime = currentTime.add(const Duration(seconds: 19));
      expect(rateLimiter.isLocked, true);
      expect(rateLimiter.remainingSeconds, 1);

      // Advance 2 more seconds (total 31s elapsed -> expired)
      currentTime = currentTime.add(const Duration(seconds: 2));
      expect(rateLimiter.isLocked, false);
      expect(rateLimiter.remainingSeconds, 0);
      expect(rateLimiter.failedAttempts, 0);
    });

    test('reset clears failed attempts and active lockout', () {
      for (int i = 0; i < 5; i++) {
        rateLimiter.recordFailedAttempt();
      }
      expect(rateLimiter.isLocked, true);

      rateLimiter.reset();

      expect(rateLimiter.isLocked, false);
      expect(rateLimiter.failedAttempts, 0);
      expect(rateLimiter.remainingSeconds, 0);
    });

    test('subsequent failed attempts while locked do not extend duration', () {
      for (int i = 0; i < 5; i++) {
        rateLimiter.recordFailedAttempt();
      }
      final lockedUntil = rateLimiter.lockedUntil;

      // Further failed attempts while locked
      rateLimiter.recordFailedAttempt();
      rateLimiter.recordFailedAttempt();

      expect(rateLimiter.lockedUntil, lockedUntil);
      expect(rateLimiter.failedAttempts, 5);
    });
  });
}
