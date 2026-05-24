// lib/features/auth/domain/repositories/auth_repository.dart
//
// AuthRepository — abstract interface for authentication operations.

import '../entities/app_user.dart';

/// Abstract repository interface for all authentication operations.
///
/// Implementations live in the data layer and are injected at the app root.
abstract class AuthRepository {
  /// Stream of the currently authenticated user.
  ///
  /// Emits the current [AppUser] when authenticated, or `null` when signed out.
  /// Automatically emits on app restart if a session exists.
  Stream<AppUser?> get authStateChanges;

  /// Creates a new account with [email] and [password].
  ///
  /// Also writes the new user profile to Firestore at `users/{uid}`.
  /// Throws [FirebaseAuthException] on failure.
  Future<void> signUpWithEmail(String email, String password);

  /// Signs in an existing user with [email] and [password].
  ///
  /// Throws [FirebaseAuthException] on failure.
  Future<void> signInWithEmail(String email, String password);

  /// Signs in using the Google Sign-In flow.
  ///
  /// Writes a Firestore user document on first sign-in.
  /// Throws [FirebaseAuthException] on failure.
  Future<void> signInWithGoogle();

  /// Sends a password-reset email to [email].
  ///
  /// Throws [FirebaseAuthException] on failure.
  Future<void> sendPasswordResetEmail(String email);

  /// Signs out the currently authenticated user.
  Future<void> signOut();
}
