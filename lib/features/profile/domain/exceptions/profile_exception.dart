// lib/features/profile/domain/exceptions/profile_exception.dart
//
// ProfileException — domain-level profile error.

/// Thrown by [ProfileRepository] implementations when a profile
/// operation fails.
class ProfileException implements Exception {
  const ProfileException(this.message);

  /// A human-readable description of the error.
  final String message;

  @override
  String toString() => 'ProfileException(message: $message)';
}
