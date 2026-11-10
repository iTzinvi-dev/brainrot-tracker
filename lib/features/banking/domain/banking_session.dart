/// Domain model representing a banking / productivity focus session.
class BankingSession {
  final int? id;
  final String sessionId;
  final int startTimestamp;
  final int? endTimestamp;
  final String reason;
  final int autoResumeMinutes;
  final String status; // active, completed, cancelled

  const BankingSession({
    this.id,
    required this.sessionId,
    required this.startTimestamp,
    this.endTimestamp,
    this.reason = 'banking',
    this.autoResumeMinutes = 15,
    this.status = 'active',
  });

  bool get isActive => status == 'active';

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'session_id': sessionId,
    'start_timestamp': startTimestamp,
    'end_timestamp': endTimestamp,
    'reason': reason,
    'auto_resume_minutes': autoResumeMinutes,
    'status': status,
  };

  factory BankingSession.fromMap(Map<String, dynamic> map) => BankingSession(
    id: map['id'] as int?,
    sessionId: map['session_id'] as String,
    startTimestamp: map['start_timestamp'] as int,
    endTimestamp: map['end_timestamp'] as int?,
    reason: map['reason'] as String? ?? 'banking',
    autoResumeMinutes: map['auto_resume_minutes'] as int? ?? 15,
    status: map['status'] as String? ?? 'active',
  );

  BankingSession copyWith({
    int? id,
    String? sessionId,
    int? startTimestamp,
    int? endTimestamp,
    String? reason,
    int? autoResumeMinutes,
    String? status,
  }) {
    return BankingSession(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      startTimestamp: startTimestamp ?? this.startTimestamp,
      endTimestamp: endTimestamp ?? this.endTimestamp,
      reason: reason ?? this.reason,
      autoResumeMinutes: autoResumeMinutes ?? this.autoResumeMinutes,
      status: status ?? this.status,
    );
  }
}
