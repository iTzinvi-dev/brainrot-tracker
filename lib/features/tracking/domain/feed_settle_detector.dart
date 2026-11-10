/// Client-side zero-tree-traversal short-form video settle detector.
/// Mirrors native PlatformDetector logic for contract verification and event filtering.
class FeedSettleDetector {
  final String packageName;
  final Set<int> _seenIndices = {};
  int _epoch = 0;
  int _lastIndex = -1;
  int _lastItemCount = -1;

  int _accumulatedDeltaY = 0;
  int _lastDeltaTime = 0;
  final int deltaDebounceWindowMs;
  final int deltaThresholdPx;

  FeedSettleDetector({
    required this.packageName,
    this.deltaDebounceWindowMs = 600,
    this.deltaThresholdPx = 400,
  });

  int get epoch => _epoch;
  int get lastIndex => _lastIndex;
  int get lastItemCount => _lastItemCount;
  Set<int> get seenIndices => Set.unmodifiable(_seenIndices);

  /// Key hash algorithm computing unique identifier per epoch and index.
  static int computeKey(int epoch, int toIndex) => epoch * 100000 + toIndex;

  /// Evaluates whether a feed swipe has settled on a new unique video.
  bool accept({
    required int fromIndex,
    required int toIndex,
    required int itemCount,
    int scrollDeltaY = 0,
    int nowMs = 0,
  }) {
    // Strategy 1: Page index settle detection
    if (toIndex >= 0 && itemCount >= 0) {
      if (fromIndex >= 0 && fromIndex != toIndex) {
        return false;
      }

      // Pull-to-refresh / feed reload detection
      if (itemCount < _lastItemCount && toIndex < _lastIndex) {
        _epoch++;
        _seenIndices.clear();
      }
      _lastItemCount = itemCount;
      _lastIndex = toIndex;

      final key = computeKey(_epoch, toIndex);
      return _seenIndices.add(key);
    }

    // Strategy 2: Accumulated scroll delta fallback
    if (scrollDeltaY != 0) {
      if (nowMs - _lastDeltaTime > deltaDebounceWindowMs) {
        _accumulatedDeltaY = 0;
      }
      _lastDeltaTime = nowMs;
      _accumulatedDeltaY += scrollDeltaY.abs();

      if (_accumulatedDeltaY >= deltaThresholdPx) {
        _accumulatedDeltaY = 0;
        return true;
      }
    }

    return false;
  }

  /// Resets detector state across session boundaries.
  void reset() {
    _seenIndices.clear();
    _epoch = 0;
    _lastIndex = -1;
    _lastItemCount = -1;
    _accumulatedDeltaY = 0;
    _lastDeltaTime = 0;
  }
}
