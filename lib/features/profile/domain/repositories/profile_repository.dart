// lib/features/profile/domain/repositories/profile_repository.dart
//
// ProfileRepository — abstract interface for all profile operations.

import '../entities/user_profile.dart';

/// Abstract repository interface for user profile operations.
///
/// Implementations live in the data layer and are injected at the app root.
abstract class ProfileRepository {
  /// Fetches the profile for any user by UID (own or other user).
  Future<UserProfile> getProfile(String uid);

  /// Updates editable profile fields for the currently authenticated user.
  ///
  /// Only pass non-null values for fields being changed.
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? bio,
    String? avatarUrl,
  });

  /// Uploads avatar image bytes to Firebase Storage at `avatars/{uid}`.
  ///
  /// Returns the public HTTPS download URL.
  Future<String> uploadAvatar({
    required String uid,
    required String localFilePath,
  });

  /// Deletes the currently authenticated user's account:
  ///
  /// 1. Deletes `users/{uid}` Firestore document.
  /// 2. Deletes `avatars/{uid}` from Firebase Storage (swallows NotFound).
  /// 3. Calls `FirebaseAuth.instance.currentUser!.delete()`.
  Future<void> deleteAccount();
}
