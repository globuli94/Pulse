// lib/features/auth/domain/entities/app_user.dart
//
// AppUser — pure Dart domain entity representing an authenticated user.

/// Represents an authenticated application user.
///
/// This entity contains no Firebase imports and is safe to use across
/// all application layers.
class AppUser {
  /// Creates an [AppUser].
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  /// The unique Firebase Auth user ID.
  final String uid;

  /// The user's email address.
  final String? email;

  /// The user's display name.
  final String displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          other.uid == uid &&
          other.email == email &&
          other.displayName == displayName;

  @override
  int get hashCode => uid.hashCode ^ email.hashCode ^ displayName.hashCode;
}
