// lib/features/auth/domain/exceptions/auth_exception.dart
//
// AuthException — domain-level authentication error.

/// Thrown by [AuthRepository] implementations when an authentication
/// operation fails.
///
/// [code] mirrors the Firebase Auth error codes so BLoC layers can produce
/// user-facing messages without importing firebase_auth.
class AuthException implements Exception {
  const AuthException({required this.code, this.message});

  /// The error code (e.g. 'user-not-found', 'wrong-password').
  final String code;

  /// Optional human-readable description for debugging.
  final String? message;

  @override
  String toString() => 'AuthException(code: $code, message: $message)';
}
