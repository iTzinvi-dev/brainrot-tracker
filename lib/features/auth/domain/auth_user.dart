/// Represents an authenticated user or guest in Brainrot Tracker Pro.
class AuthUser {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isGuest;
  final DateTime createdAt;

  const AuthUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isGuest = false,
    required this.createdAt,
  });

  /// Helper factory to generate a guest user instance.
  factory AuthUser.guest({String? id}) {
    return AuthUser(
      id: id ?? 'guest_${DateTime.now().millisecondsSinceEpoch}',
      email: null,
      displayName: 'Guest Operative',
      photoUrl: null,
      isGuest: true,
      createdAt: DateTime.now(),
    );
  }

  AuthUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isGuest,
    DateTime? createdAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isGuest: isGuest ?? this.isGuest,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isGuest': isGuest,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    return AuthUser(
      id: map['id'] as String,
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      isGuest: (map['isGuest'] as bool?) ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          displayName == other.displayName &&
          photoUrl == other.photoUrl &&
          isGuest == other.isGuest;

  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      displayName.hashCode ^
      photoUrl.hashCode ^
      isGuest.hashCode;

  @override
  String toString() =>
      'AuthUser(id: $id, email: $email, displayName: $displayName, isGuest: $isGuest)';
}
