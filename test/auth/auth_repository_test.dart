import 'package:flutter_test/flutter_test.dart';
import 'package:brainrot_tracker_pro/features/auth/data/mock_auth_repository.dart';
import 'package:brainrot_tracker_pro/features/auth/domain/auth_failure.dart';

void main() {
  group('MockAuthRepository Tests', () {
    late MockAuthRepository repository;

    setUp(() {
      repository = MockAuthRepository(seedDevAccount: true);
    });

    tearDown(() {
      repository.dispose();
    });

    test('sign in with valid pre-seeded credentials succeeds', () async {
      final user = await repository.signInWithEmailAndPassword(
        'dev@brainrot.app',
        'Password123!',
      );

      expect(user.id, 'dev_user_001');
      expect(user.email, 'dev@brainrot.app');
      expect(user.isGuest, false);
      expect(repository.currentUser, equals(user));
    });

    test('sign in with incorrect password throws InvalidCredentialsFailure', () async {
      expect(
        () => repository.signInWithEmailAndPassword('dev@brainrot.app', 'WrongPass1!'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
    });

    test('sign in with unseeded email throws InvalidCredentialsFailure', () async {
      expect(
        () => repository.signInWithEmailAndPassword('ghost@brainrot.app', 'Password123!'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
    });

    test('createUserWithEmailAndPassword registers new operative account', () async {
      final user = await repository.createUserWithEmailAndPassword(
        'agent99@brainrot.app',
        'SecurePass2026!',
        displayName: 'Agent 99',
      );

      expect(user.email, 'agent99@brainrot.app');
      expect(user.displayName, 'Agent 99');
      expect(user.isGuest, false);
      expect(repository.currentUser?.id, user.id);

      // Verify immediate login with newly registered credentials
      await repository.signOut();
      final loggedIn = await repository.signInWithEmailAndPassword(
        'agent99@brainrot.app',
        'SecurePass2026!',
      );
      expect(loggedIn.id, user.id);
    });

    test('createUserWithEmailAndPassword rejects duplicate email', () async {
      expect(
        () => repository.createUserWithEmailAndPassword('dev@brainrot.app', 'Password123!'),
        throwsA(isA<EmailAlreadyInUseFailure>()),
      );
    });

    test('createUserWithEmailAndPassword rejects weak password', () async {
      expect(
        () => repository.createUserWithEmailAndPassword('new@brainrot.app', 'weak'),
        throwsA(isA<WeakPasswordFailure>()),
      );
    });

    test('signInAnonymously establishes guest operative session', () async {
      final guest = await repository.signInAnonymously();

      expect(guest.isGuest, true);
      expect(guest.id, startsWith('guest_'));
      expect(guest.displayName, 'Guest Operative');
      expect(repository.currentUser?.id, guest.id);
    });

    test('upgradeGuestWithEmail links permanent credentials and preserves UID', () async {
      // Step 1: Start as guest operative
      final guest = await repository.signInAnonymously();
      final originalId = guest.id;

      // Step 2: Upgrade account
      final upgraded = await repository.upgradeGuestWithEmail(
        'upgraded@brainrot.app',
        'UpgradedP@ss123!',
        displayName: 'Veteran Operative',
      );

      // Verify UID was strictly preserved to maintain local history & pet stats
      expect(upgraded.id, originalId);
      expect(upgraded.isGuest, false);
      expect(upgraded.email, 'upgraded@brainrot.app');
      expect(upgraded.displayName, 'Veteran Operative');
      expect(repository.currentUser?.id, originalId);
    });

    test('upgradeGuestWithGoogle preserves original guest UID', () async {
      final guest = await repository.signInAnonymously();
      final originalId = guest.id;

      final upgraded = await repository.upgradeGuestWithGoogle();

      expect(upgraded.id, originalId);
      expect(upgraded.isGuest, false);
      expect(upgraded.email, 'upgraded.google@brainrot.app');
      expect(repository.currentUser?.id, originalId);
    });

    test('signOut terminates active session and sets currentUser to null', () async {
      await repository.signInWithEmailAndPassword('dev@brainrot.app', 'Password123!');
      expect(repository.currentUser, isNotNull);

      await repository.signOut();
      expect(repository.currentUser, isNull);
    });
  });
}
