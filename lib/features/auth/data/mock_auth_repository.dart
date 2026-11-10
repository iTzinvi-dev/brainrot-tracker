import 'dart:async';
import '../domain/auth_failure.dart';
import '../domain/auth_user.dart';
import '../../../../core/security/input_sanitizer.dart';
import 'auth_repository.dart';

/// In-memory implementation of [AuthRepository] for development, testing, and offline modes.
/// Contains pre-seeded development credentials and full state transitions.
class MockAuthRepository implements AuthRepository {
  final StreamController<AuthUser?> _authStateController =
      StreamController<AuthUser?>.broadcast();

  final Map<String, _MockAccount> _accounts = {};
  AuthUser? _currentUser;

  MockAuthRepository({bool seedDevAccount = true}) {
    if (seedDevAccount) {
      _seedDefaultAccount();
    }
  }

  void _seedDefaultAccount() {
    final devUser = AuthUser(
      id: 'dev_user_001',
      email: 'dev@brainrot.app',
      displayName: 'Dev Operative',
      photoUrl: null,
      isGuest: false,
      createdAt: DateTime(2026, 1, 1),
    );
    _accounts['dev@brainrot.app'] = _MockAccount(
      user: devUser,
      password: 'Password123!',
    );
  }

  @override
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<AuthUser> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final cleanEmail = InputSanitizer.sanitizeText(email).toLowerCase();
    final account = _accounts[cleanEmail];

    if (account == null || account.password != password) {
      throw const InvalidCredentialsFailure();
    }

    _currentUser = account.user;
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<AuthUser> createUserWithEmailAndPassword(
    String email,
    String password, {
    String? displayName,
  }) async {
    final cleanEmail = InputSanitizer.sanitizeText(email).toLowerCase();

    if (!InputSanitizer.isValidEmail(cleanEmail)) {
      throw const InvalidCredentialsFailure('Invalid email address format.');
    }

    if (!InputSanitizer.isStrongPassword(password)) {
      throw const WeakPasswordFailure();
    }

    if (_accounts.containsKey(cleanEmail)) {
      throw const EmailAlreadyInUseFailure();
    }

    final newUser = AuthUser(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      email: cleanEmail,
      displayName: InputSanitizer.sanitizeText(displayName ?? cleanEmail.split('@').first),
      photoUrl: null,
      isGuest: false,
      createdAt: DateTime.now(),
    );

    _accounts[cleanEmail] = _MockAccount(user: newUser, password: password);
    _currentUser = newUser;
    _authStateController.add(_currentUser);
    return newUser;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    final googleUser = AuthUser(
      id: 'google_user_001',
      email: 'operative.google@brainrot.app',
      displayName: 'Google Cyber Operative',
      photoUrl: 'https://brainrot.app/avatars/google.png',
      isGuest: false,
      createdAt: DateTime.now(),
    );

    _currentUser = googleUser;
    _authStateController.add(_currentUser);
    return googleUser;
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    final guestUser = AuthUser.guest();
    _currentUser = guestUser;
    _authStateController.add(_currentUser);
    return guestUser;
  }

  @override
  Future<AuthUser> upgradeGuestWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    if (_currentUser == null || !_currentUser!.isGuest) {
      throw const GuestUpgradeFailure('Active user is not a guest.');
    }

    final cleanEmail = InputSanitizer.sanitizeText(email).toLowerCase();

    if (!InputSanitizer.isValidEmail(cleanEmail)) {
      throw const InvalidCredentialsFailure('Invalid email address format.');
    }

    if (!InputSanitizer.isStrongPassword(password)) {
      throw const WeakPasswordFailure();
    }

    if (_accounts.containsKey(cleanEmail)) {
      throw const EmailAlreadyInUseFailure();
    }

    // Preserve the original guest UID to retain all local event logs & stats
    final upgradedUser = _currentUser!.copyWith(
      email: cleanEmail,
      displayName: InputSanitizer.sanitizeText(displayName ?? cleanEmail.split('@').first),
      isGuest: false,
    );

    _accounts[cleanEmail] = _MockAccount(user: upgradedUser, password: password);
    _currentUser = upgradedUser;
    _authStateController.add(_currentUser);
    return upgradedUser;
  }

  @override
  Future<AuthUser> upgradeGuestWithGoogle() async {
    if (_currentUser == null || !_currentUser!.isGuest) {
      throw const GuestUpgradeFailure('Active user is not a guest.');
    }

    // Preserve original UID
    final upgradedUser = _currentUser!.copyWith(
      email: 'upgraded.google@brainrot.app',
      displayName: 'Upgraded Cyber Operative',
      photoUrl: 'https://brainrot.app/avatars/google.png',
      isGuest: false,
    );

    _currentUser = upgradedUser;
    _authStateController.add(_currentUser);
    return upgradedUser;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  void dispose() {
    _authStateController.close();
  }
}

class _MockAccount {
  final AuthUser user;
  final String password;

  const _MockAccount({required this.user, required this.password});
}
