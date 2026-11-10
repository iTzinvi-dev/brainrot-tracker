/// Result of evaluating a swipe event against the velocity sliding window.
class VelocityResult {
  final bool isSpike;
  final bool isRapidDwell;
  final double velocitySpm;
  final int windowCount;

  const VelocityResult({
    required this.isSpike,
    required this.isRapidDwell,
    required this.velocitySpm,
    required this.windowCount,
  });
}

/// Real-time sliding window algorithm detecting rapid skimming (>40 swipes/min, dwell <1800ms).
class VelocityLimiterAlgorithm {
  final double spikeThresholdSpm;
  final int windowSeconds;
  final int rapidDwellMsThreshold;

  final List<int> _timestamps = [];
  bool _isSpikeDetected = false;

  VelocityLimiterAlgorithm({
    this.spikeThresholdSpm = 40.0,
    this.windowSeconds = 60,
    this.rapidDwellMsThreshold = 1800,
  });

  /// Evaluates and returns current velocity in swipes per minute over the sliding window.
  double get currentVelocitySpm {
    if (_timestamps.length < 2) return 0.0;
    final deltaSec = (_timestamps.last - _timestamps.first) / 1000.0;
    if (deltaSec <= 0.0) return 0.0;
    final rate = ((_timestamps.length - 1) / deltaSec) * 60.0;
    return rate;
  }

  /// Whether a high-frequency velocity spike has been triggered.
  bool get isSpikeDetected => _isSpikeDetected;

  /// Count of swipe events in the active sliding window.
  int get activeWindowCount => _timestamps.length;

  /// Records a swipe occurrence, evicts aged timestamps, and evaluates rate thresholds.
  VelocityResult recordSwipe({int? timestampMs, int? dwellTimeMs}) {
    final now = timestampMs ?? DateTime.now().millisecondsSinceEpoch;

    // Evict timestamps outside the active sliding window
    final cutoff = now - (windowSeconds * 1000);
    _timestamps.removeWhere((t) => t < cutoff);

    // Record current timestamp
    _timestamps.add(now);

    // Calculate current rate safely
    final velocity = currentVelocitySpm;
    final isSpike = velocity >= spikeThresholdSpm;
    if (isSpike) {
      _isSpikeDetected = true;
    }

    final isRapidDwell = dwellTimeMs != null && dwellTimeMs < rapidDwellMsThreshold;

    return VelocityResult(
      isSpike: isSpike,
      isRapidDwell: isRapidDwell,
      velocitySpm: velocity,
      windowCount: _timestamps.length,
    );
  }

  /// Resets historical swipe window and clearing spike detection state.
  void reset() {
    _timestamps.clear();
    _isSpikeDetected = false;
  }
}
