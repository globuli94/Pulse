// lib/features/profile/domain/repositories/profile_repository.dart
//
// ProfileRepository — domain interface for user profile operations.

import '../entities/user_profile.dart';

/// Abstract repository for user profile operations.
abstract class ProfileRepository {
  /// Fetches the profile for [uid].
  Future<UserProfile> getProfile(String uid);

  /// Updates the [displayName] and [bio] fields for [uid].
  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String bio,
  });

  /// Uploads [imageBytes] as the avatar for [uid].
  ///
  /// Returns the public download URL of the uploaded avatar.
  Future<String> uploadAvatar({
    required String uid,
    required List<int> imageBytes,
    required String filename,
  });

  /// Deletes the Firestore document and the Firebase Auth account for [uid].
  ///
  /// The caller must be the currently signed-in user.
  Future<void> deleteAccount(String uid);
}
