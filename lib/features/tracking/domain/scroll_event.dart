import 'package:brainrot_tracker_pro/features/tracking/domain/platform_type.dart';

/// Immutable domain model representing a discrete scroll / video settlement event.
class ScrollEvent {
  final int? id;
  final String sessionId;
  final PlatformType platform;
  final int timestamp; // epoch ms UTC
  final int pageIndex;
  final int durationMs;
  final bool isRapidScroll;

  const ScrollEvent({
    this.id,
    required this.sessionId,
    required this.platform,
    required this.timestamp,
    required this.pageIndex,
    this.durationMs = 0,
    this.isRapidScroll = false,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'session_id': sessionId,
    'platform': platform.name,
    'timestamp': timestamp,
    'page_index': pageIndex,
    'duration_ms': durationMs,
    'is_rapid_scroll': isRapidScroll ? 1 : 0,
  };

  factory ScrollEvent.fromMap(Map<String, dynamic> map) => ScrollEvent(
    id: map['id'] as int?,
    sessionId: map['session_id'] as String,
    platform: PlatformType.values.byName(map['platform'] as String),
    timestamp: map['timestamp'] as int,
    pageIndex: map['page_index'] as int,
    durationMs: map['duration_ms'] as int? ?? 0,
    isRapidScroll: (map['is_rapid_scroll'] as int? ?? 0) == 1,
  );

  ScrollEvent copyWith({
    int? id,
    String? sessionId,
    PlatformType? platform,
    int? timestamp,
    int? pageIndex,
    int? durationMs,
    bool? isRapidScroll,
  }) {
    return ScrollEvent(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      platform: platform ?? this.platform,
      timestamp: timestamp ?? this.timestamp,
      pageIndex: pageIndex ?? this.pageIndex,
      durationMs: durationMs ?? this.durationMs,
      isRapidScroll: isRapidScroll ?? this.isRapidScroll,
    );
  }
}
