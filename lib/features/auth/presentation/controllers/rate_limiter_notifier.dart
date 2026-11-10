import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/rate_limiter.dart';

class RateLimiterState {
  final bool isLocked;
  final int remainingSeconds;
  final int failedAttempts;

  const RateLimiterState({
    this.isLocked = false,
    this.remainingSeconds = 0,
    this.failedAttempts = 0,
  });

  RateLimiterState copyWith({
    bool? isLocked,
    int? remainingSeconds,
    int? failedAttempts,
  }) {
    return RateLimiterState(
      isLocked: isLocked ?? this.isLocked,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      failedAttempts: failedAttempts ?? this.failedAttempts,
    );
  }
}

class RateLimiterNotifier extends StateNotifier<RateLimiterState> {
  final RateLimiter _rateLimiter;
  Timer? _countdownTimer;

  RateLimiterNotifier({RateLimiter? rateLimiter})
      : _rateLimiter = rateLimiter ?? RateLimiter(),
        super(const RateLimiterState()) {
    _syncState();
  }

  void _syncState() {
    state = RateLimiterState(
      isLocked: _rateLimiter.isLocked,
      remainingSeconds: _rateLimiter.remainingSeconds,
      failedAttempts: _rateLimiter.failedAttempts,
    );
  }

  void recordFailure() {
    _rateLimiter.recordFailedAttempt();
    _syncState();

    if (_rateLimiter.isLocked) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_rateLimiter.isLocked || _rateLimiter.remainingSeconds <= 0) {
        timer.cancel();
        _rateLimiter.reset();
        _syncState();
      } else {
        state = state.copyWith(
          isLocked: true,
          remainingSeconds: _rateLimiter.remainingSeconds,
        );
      }
    });
  }

  void reset() {
    _countdownTimer?.cancel();
    _rateLimiter.reset();
    _syncState();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}

final rateLimiterProvider =
    StateNotifierProvider<RateLimiterNotifier, RateLimiterState>((ref) {
  return RateLimiterNotifier();
});
