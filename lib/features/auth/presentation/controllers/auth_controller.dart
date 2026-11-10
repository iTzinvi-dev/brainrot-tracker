import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../data/mock_auth_repository.dart';
import '../../domain/auth_failure.dart';
import 'auth_state.dart';
import 'rate_limiter_notifier.dart';

/// Provider for AuthRepository. Defaults to [MockAuthRepository] for development & testing.
/// Can be overridden in production with [FirebaseAuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

/// Riverpod controller managing authentication workflows and rate limiting integration.
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final Ref _ref;
  StreamSubscription? _authSubscription;

  AuthController({
    required AuthRepository authRepository,
    required Ref ref,
  })  : _authRepository = authRepository,
        _ref = ref,
        super(const AuthState(status: AuthStatus.initial)) {
    _init();
  }

  void _init() {
    final current = _authRepository.currentUser;
    if (current != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: current,
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }

    _authSubscription = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
        );
      }
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    final rateLimiterState = _ref.read(rateLimiterProvider);
    if (rateLimiterState.isLocked) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Locked out. Please wait ${rateLimiterState.remainingSeconds}s.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await _authRepository.signInWithEmailAndPassword(email, password);
      _ref.read(rateLimiterProvider.notifier).reset();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
    } on AuthFailure catch (e) {
      _ref.read(rateLimiterProvider.notifier).recordFailure();
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
        isLoading: false,
      );
    } catch (e) {
      _ref.read(rateLimiterProvider.notifier).recordFailure();
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'An unexpected error occurred during sign in.',
        isLoading: false,
      );
    }
  }

  Future<void> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await _authRepository.createUserWithEmailAndPassword(
        email,
        password,
        displayName: displayName,
      );
      _ref.read(rateLimiterProvider.notifier).reset();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
    } on AuthFailure catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'An unexpected error occurred during account creation.',
        isLoading: false,
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await _authRepository.signInWithGoogle();
      _ref.read(rateLimiterProvider.notifier).reset();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
    } on AuthFailure catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Google authentication failed.',
        isLoading: false,
      );
    }
  }

  Future<void> signInAsGuest() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await _authRepository.signInAnonymously();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
    } on AuthFailure catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Guest initialization failed.',
        isLoading: false,
      );
    }
  }

  Future<void> upgradeGuestWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await _authRepository.upgradeGuestWithEmail(
        email,
        password,
        displayName: displayName,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
    } on AuthFailure catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Failed to upgrade guest account.',
        isLoading: false,
      );
    }
  }

  Future<void> upgradeGuestWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await _authRepository.upgradeGuestWithGoogle();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
    } on AuthFailure catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Failed to link Google account to guest.',
        isLoading: false,
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _authRepository.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthController(authRepository: authRepo, ref: ref);
});
