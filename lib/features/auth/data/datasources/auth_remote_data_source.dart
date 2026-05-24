// lib/features/auth/data/datasources/auth_remote_data_source.dart
//
// AuthRemoteDataSource — abstract interface for Firebase Auth + Firestore operations.

import 'package:firebase_auth/firebase_auth.dart';

/// Abstract data source for authentication-related remote operations.
abstract class AuthRemoteDataSource {
  /// Raw Firebase Auth state stream.
  Stream<User?> get authStateChanges;

  /// Creates a new user with email/password and writes a Firestore profile.
  Future<void> signUpWithEmail(String email, String password);

  /// Signs in with email/password.
  Future<void> signInWithEmail(String email, String password);

  /// Signs in via Google Sign-In and writes a Firestore profile for new users.
  Future<void> signInWithGoogle();

  /// Sends a password-reset email.
  Future<void> sendPasswordResetEmail(String email);

  /// Signs out the current user.
  Future<void> signOut();
}
