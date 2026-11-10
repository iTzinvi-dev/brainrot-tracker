import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_user.dart';
import '../../../../core/logging/safe_logger.dart';
import '../../../../core/security/input_sanitizer.dart';
import 'auth_repository.dart';

/// Production Firebase implementation of [AuthRepository] with Google Sign-In and linkWithCredential support.
class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final SafeLogger _logger;

  FirebaseAuthRepository({
    fb.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    SafeLogger? logger,
  })  : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email']),
        _logger = logger ?? const SafeLogger('FirebaseAuthRepository');

  @override
  Stream<AuthUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_mapFirebaseUser);
  }

  @override
  AuthUser? get currentUser => _mapFirebaseUser(_firebaseAuth.currentUser);

  AuthUser? _mapFirebaseUser(fb.User? user) {
    if (user == null) return null;
    return AuthUser(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isGuest: user.isAnonymous,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  @override
  Future<AuthUser> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final cleanEmail = InputSanitizer.sanitizeText(email).trim().toLowerCase();
    _logger.info('Attempting sign in for user: $cleanEmail');

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final user = _mapFirebaseUser(credential.user);
      if (user == null) {
        throw const ServerFailure('User payload empty after successful sign in.');
      }
      return user;
    } on fb.FirebaseAuthException catch (e) {
      _logger.warning('Firebase sign-in failed with code: ${e.code}');
      throw _handleFirebaseAuthException(e);
    } catch (e, st) {
      _logger.error('Unexpected error during sign in', e, st);
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<AuthUser> createUserWithEmailAndPassword(
    String email,
    String password, {
    String? displayName,
  }) async {
    final cleanEmail = InputSanitizer.sanitizeText(email).trim().toLowerCase();

    if (!InputSanitizer.isValidEmail(cleanEmail)) {
      throw const InvalidCredentialsFailure('Invalid email address format.');
    }

    if (!InputSanitizer.isStrongPassword(password)) {
      throw const WeakPasswordFailure();
    }

    _logger.info('Creating account for: $cleanEmail');

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final cleanName = displayName != null ? InputSanitizer.sanitizeText(displayName) : null;
      if (cleanName != null && cleanName.isNotEmpty) {
        await credential.user?.updateDisplayName(cleanName);
      }

      final user = _mapFirebaseUser(credential.user);
      if (user == null) {
        throw const ServerFailure('User payload empty after registration.');
      }
      return user;
    } on fb.FirebaseAuthException catch (e) {
      _logger.warning('Firebase create user failed with code: ${e.code}');
      throw _handleFirebaseAuthException(e);
    } catch (e, st) {
      _logger.error('Unexpected error during account creation', e, st);
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    _logger.info('Initiating Google Sign-In flow');
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const InvalidCredentialsFailure('Google sign-in was cancelled by user.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final authResult = await _firebaseAuth.signInWithCredential(credential);
      final user = _mapFirebaseUser(authResult.user);
      if (user == null) {
        throw const ServerFailure('Google sign in returned no user.');
      }
      return user;
    } on fb.FirebaseAuthException catch (e) {
      _logger.warning('Google sign in Firebase error: ${e.code}');
      throw _handleFirebaseAuthException(e);
    } catch (e, st) {
      _logger.error('Google sign in error', e, st);
      if (e is AuthFailure) rethrow;
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    _logger.info('Signing in as guest');
    try {
      final credential = await _firebaseAuth.signInAnonymously();
      final user = _mapFirebaseUser(credential.user);
      if (user == null) {
        throw const ServerFailure('Guest sign in failed to initialize user.');
      }
      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e, st) {
      _logger.error('Guest sign in error', e, st);
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<AuthUser> upgradeGuestWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null || !currentUser.isAnonymous) {
      throw const GuestUpgradeFailure('Active user is not an anonymous guest.');
    }

    final cleanEmail = InputSanitizer.sanitizeText(email).trim().toLowerCase();
    if (!InputSanitizer.isValidEmail(cleanEmail)) {
      throw const InvalidCredentialsFailure('Invalid email address format.');
    }

    if (!InputSanitizer.isStrongPassword(password)) {
      throw const WeakPasswordFailure();
    }

    try {
      final credential = fb.EmailAuthProvider.credential(
        email: cleanEmail,
        password: password,
      );
      final result = await currentUser.linkWithCredential(credential);

      final cleanName = displayName != null ? InputSanitizer.sanitizeText(displayName) : null;
      if (cleanName != null && cleanName.isNotEmpty) {
        await result.user?.updateDisplayName(cleanName);
      }

      final user = _mapFirebaseUser(result.user);
      if (user == null) {
        throw const GuestUpgradeFailure('Upgraded guest user null.');
      }
      return user;
    } on fb.FirebaseAuthException catch (e) {
      _logger.warning('Guest email link error: ${e.code}');
      throw _handleFirebaseAuthException(e);
    } catch (e, st) {
      _logger.error('Unexpected guest upgrade error', e, st);
      throw GuestUpgradeFailure(e.toString());
    }
  }

  @override
  Future<AuthUser> upgradeGuestWithGoogle() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null || !currentUser.isAnonymous) {
      throw const GuestUpgradeFailure('Active user is not an anonymous guest.');
    }

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const GuestUpgradeFailure('Google link was cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await currentUser.linkWithCredential(credential);
      final user = _mapFirebaseUser(result.user);
      if (user == null) {
        throw const GuestUpgradeFailure('Google guest upgrade produced empty user.');
      }
      return user;
    } on fb.FirebaseAuthException catch (e) {
      _logger.warning('Guest google link error: ${e.code}');
      throw _handleFirebaseAuthException(e);
    } catch (e, st) {
      _logger.error('Unexpected guest google upgrade error', e, st);
      throw GuestUpgradeFailure(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _firebaseAuth.signOut();
  }

  AuthFailure _handleFirebaseAuthException(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const InvalidCredentialsFailure();
      case 'email-already-in-use':
      case 'credential-already-in-use':
        return const EmailAlreadyInUseFailure();
      case 'weak-password':
        return const WeakPasswordFailure();
      case 'too-many-requests':
        return const TooManyRequestsFailure();
      case 'network-request-failed':
        return const NetworkFailure();
      default:
        return ServerFailure(e.message ?? 'Authentication error [${e.code}]');
    }
  }
}
