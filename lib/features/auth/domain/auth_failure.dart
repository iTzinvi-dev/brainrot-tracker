/// Domain failures representing authentication error states.
abstract class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => message;
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure([
    super.message = 'Invalid email or password combination.',
  ]);
}

class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure([
    super.message = 'An account with this email already exists.',
  ]);
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure([
    super.message = 'Password does not meet 5-point security requirements.',
  ]);
}

class TooManyRequestsFailure extends AuthFailure {
  final int remainingSeconds;
  const TooManyRequestsFailure({
    this.remainingSeconds = 30,
    String? message,
  }) : super(message ?? 'Too many failed attempts. Locked out for $remainingSeconds seconds.');
}

class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure([
    super.message = 'No account found for this email address.',
  ]);
}

class NetworkFailure extends AuthFailure {
  const NetworkFailure([
    super.message = 'Network connection error. Please check your connection.',
  ]);
}

class GuestUpgradeFailure extends AuthFailure {
  const GuestUpgradeFailure([
    super.message = 'Failed to upgrade guest account. Please try again.',
  ]);
}

class ServerFailure extends AuthFailure {
  const ServerFailure([
    super.message = 'Authentication server encountered an unexpected error.',
  ]);
}
