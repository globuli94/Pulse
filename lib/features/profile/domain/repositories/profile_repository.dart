// lib/features/profile/domain/repositories/profile_repository.dart
//
// ProfileRepository — domain interface for user profile operations.

import '../entities/user_profile.dart';

/// Abstract repository for user profile operations.
abstract class ProfileRepository {
  /// Fetches the profile for [uid].
  Future<UserProfile> getProfile(String uid);

  /// Updates the [displayName] and [bio] fields for [uid].
  ///
  /// Returns the updated [UserProfile].
  Future<UserProfile> updateProfile({
    required String uid,
    required String displayName,
    required String bio,
  });

  /// Uploads the image at [imagePath] as the avatar for [uid].
  ///
  /// Returns the updated [UserProfile] with the new avatar URL.
  Future<UserProfile> uploadAvatar({
    required String uid,
    required String imagePath,
  });

  /// Deletes the Firestore document and the Firebase Auth account for [uid].
  ///
  /// The caller must be the currently signed-in user.
  Future<void> deleteAccount({required String uid});
}
