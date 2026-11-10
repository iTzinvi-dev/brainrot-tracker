import '../domain/auth_user.dart';

/// Abstract contract for authentication operations in Brainrot Tracker Pro.
abstract class AuthRepository {
  /// Stream emitting the currently authenticated user or null.
  Stream<AuthUser?> get authStateChanges;

  /// Current user snapshot, or null if unauthenticated.
  AuthUser? get currentUser;

  /// Authenticate using email and password.
  Future<AuthUser> signInWithEmailAndPassword(String email, String password);

  /// Create a new account with email, password, and optional display name.
  Future<AuthUser> createUserWithEmailAndPassword(
    String email,
    String password, {
    String? displayName,
  });

  /// Sign in using Google OAuth provider.
  Future<AuthUser> signInWithGoogle();

  /// Sign in anonymously as a guest operative.
  Future<AuthUser> signInAnonymously();

  /// Upgrade an existing guest account to full email/password credentials, preserving UID.
  Future<AuthUser> upgradeGuestWithEmail(
    String email,
    String password, {
    String? displayName,
  });

  /// Upgrade an existing guest account to Google credentials, preserving UID.
  Future<AuthUser> upgradeGuestWithGoogle();

  /// Sign out the current user or guest.
  Future<void> signOut();
}
