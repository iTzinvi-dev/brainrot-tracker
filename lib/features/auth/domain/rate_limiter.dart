/// Domain rate limiter to prevent brute force attacks on authentication.
/// Enforces a maximum of 5 failed attempts before initiating a 30-second cooldown.
class RateLimiter {
  final int maxAttempts;
  final Duration lockoutDuration;
  final DateTime Function()? clock;

  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  RateLimiter({
    this.maxAttempts = 5,
    this.lockoutDuration = const Duration(seconds: 30),
    this.clock,
  });

  int get failedAttempts => _failedAttempts;
  DateTime? get lockedUntil => _lockedUntil;

  DateTime get _now => clock != null ? clock!() : DateTime.now();

  /// Whether the user is currently locked out.
  bool get isLocked {
    if (_lockedUntil == null) return false;
    if (_now.isBefore(_lockedUntil!)) {
      return true;
    }
    // Lock expired, reset state
    _lockedUntil = null;
    _failedAttempts = 0;
    return false;
  }

  /// Remaining seconds in lockout period, or 0 if not locked.
  int get remainingSeconds {
    if (!isLocked || _lockedUntil == null) return 0;
    final diff = _lockedUntil!.difference(_now);
    final remaining = diff.inSeconds + (diff.inMilliseconds % 1000 > 0 ? 1 : 0);
    return remaining > 0 ? remaining : 0;
  }

  /// Records a failed authentication attempt.
  /// If threshold is reached, locks out for [lockoutDuration].
  void recordFailedAttempt() {
    if (isLocked) return;

    _failedAttempts++;
    if (_failedAttempts >= maxAttempts) {
      _lockedUntil = _now.add(lockoutDuration);
    }
  }

  /// Resets the rate limiter on successful authentication or manual reset.
  void reset() {
    _failedAttempts = 0;
    _lockedUntil = null;
  }
}
